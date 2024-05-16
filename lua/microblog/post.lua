local curl = require("plenary.curl")
local status = require("microblog.status")
local form = require("microblog.form")
local util = require("microblog.util")
local categories = require("microblog.categories")
local config = require("microblog.config")

local M = {}

--- Get contents of a buffer or lines appearing in a visual selection
---
--- @return string
local function get_text()
  local content_lines
  if vim.fn.mode() == "n" then
    content_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  elseif vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    local visual_start = vim.fn.getpos("v")
    local visual_end = vim.fn.getpos(".")
    -- "." is the cursor position, "v" is the other end of the visual selection.
    -- They must be swapped if the cursor is at the start of the visual selection
    if visual_start[2] > visual_end[2] or (
          visual_start[2] == visual_end[2] and visual_start[3] > visual_end[3]
        ) then
      visual_start, visual_end = visual_end, visual_start
    end

    content_lines = vim.api.nvim_buf_get_text(
      0,
      visual_start[2] - 1,
      visual_start[3] - 1,
      visual_end[2] - 1,
      visual_end[3],
      {}
    )
  end
  local text = table.concat(content_lines, "\n")
  return text
end

--- Takes post data and formats body for a micropub create action
---@param data table
---@return string
local function micropub_new_post_formatter(data)
  local json_data = {
    type = { "h-entry" },
    ["mp-destination"] = util.url_to_uid(data.opts.destination),
    properties = {
      content = { { html = data.text } },
      name = { (data.opts.title or "") },
      ["post-status"] = { (data.opts.draft and "draft" or "published") },
      category = data.opts.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

--- Takes post data and formats body for a micropub replace action
---@param data table
---@return string
local function micropub_update_post_formatter(data)
  local json_data = {
    action = "update",
    url = data.opts.url,
    ["mp-destination"] = util.url_to_uid(data.opts.destination),
    replace = {
      name = { data.opts.title or "" },
      ["post-status"] = { (data.opts.draft and "draft") or "published" },
      content = { data.text },
      category = data.opts.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

--- Run curl to post to the blog
--- @param data {text: string, token: string, opts: {title: string?, destination: string, draft: boolean, url: string?, categories: string[]?}}
--- @param data_formatter function
--- @return boolean
local function send_post_request(data, data_formatter)
  local auth_string = "Bearer " .. data.token
  local formatted_data = data_formatter(data)

  local response = curl.post("https://micro.blog/micropub", {
    body = formatted_data,
    headers = {
      content_type = "application/json",
      authorization = auth_string,
    },
  })

  local response_body
  if #response.body > 0 then
    response_body = vim.fn.json_decode(response.body)
  end

  if not vim.tbl_contains({ 200, 201, 202, 204 }, response.status) then
    if response_body.error then
      print("\nPosting failed: " .. response_body.error_description)
      return false
    end
    print("\nPosting failed")
    return false
  end

  local url
  for _, header in ipairs(response.headers) do
    if string.match(header, "location: ") then
      url = string.gsub(header, "location: ", "")
    end
  end

  if url ~= status.get_status("url") then
    if response.status == 202 then
      print("\nPost made to " .. url)
    elseif response.status == 201 then
      print("\nPost url updated to " .. url)
    end
  else
    print("\nPost successfully updated")
  end

  data.opts.url = url
  status.set_post_status(data.opts)
  return true
end

---
---@param data
---@return boolean
local function finalise_post(data)
  local formatter
  if data.opts.url == "" then
    formatter = micropub_new_post_formatter
  else
    formatter = micropub_update_post_formatter
  end

  local confirm = nil
  vim.ui.select({ "Post", "Abort" }, {
    prompt = "You are about to make a post with the following settings\n"
        .. status.get_post_status_string(data.opts)
        .. "\n",
  }, function(choice)
    confirm = (choice == "Post")
  end)

  if not confirm then
    return false
  end

  local result = send_post_request(data, formatter)
  status.set_post_status(data.opts)
  return result
end

function M.publish()
  categories.refresh_categories()

  local data = {}
  data.text = get_text()
  data.token = config.app_token
  if data.token == nil then
    print("No app token found")
    return
  end
  data.opts = form.collect_user_options()

  local chosen_categories = {}
  local all_destination_categories = categories.get_categories(data.opts.destination)
  if vim.tbl_isempty(all_destination_categories) then
    print("\nNo categories found for " .. data.opts.destination)
    data.opts.categories = chosen_categories
    finalise_post(data)
  else
    form.telescope_choose_categories(all_destination_categories, chosen_categories, function()
      data.opts.categories = chosen_categories
      finalise_post(data)
    end)
  end
end

function M.quickpost()
  local data = {}
  data.text = get_text()
  data.token = config.app_token
  if data.token == nil then
    print("No app token found")
    return
  end
  data.opts = {
    title = "",
    draft = false,
    categories = {},
    destination = config.blogs[1].url,
    url = "",
  }
  local result = finalise_post(data)
  if result and config.no_save_quickpost then
    vim.bo.buftype = "nowrite"
  end
end

vim.keymap.set("v", "<leader>mg", get_text)

return M
