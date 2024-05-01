local job = require('plenary.job')
local status = require('microblog.status')
local form = require("microblog.form")
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
    local line_start = vim.fn.getpos("v")[2]
    local line_end = vim.fn.getpos(".")[2]
    content_lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
  end
  local text = table.concat(content_lines, "\n")
  return text
end


local function micropub_new_post_formatter(data)
  local json_data = {
    type = { "h-entry" },
    ["mp-destination"] = data.opts.destination,
    properties = {
      content = { { html = data.text } },
      name = { (data.opts.title or "") },
      ["post-status"] = { (data.opts.draft and "draft" or "published") },
      category = data.opts.categories
    }
  }
  return vim.fn.json_encode(json_data)
end


--- Takes post data and formats for the new post API endpoint
---@param data table
---@return string
local function micropub_update_post_formatter(data)
  local json_data = {
    action = "update",
    url = data.opts.url,
    ["mp-destination"] = data.opts.destination,
    replace = {
      name = { data.opts.title or "" },
      ["post-status"] = { (data.opts.draft and "draft") or "published" },
      content = { data.text },
      category = data.opts.categories
    }
  }
  return vim.fn.json_encode(json_data)
end


--- Run curl to post to the blog
--- @param data {text: string, token: string, opts: {title: string?, destination: string, draft: boolean, url: string?, categories: string[]?}}
--- @return boolean
local function send_post_request(data, data_formatter)
  local auth_string = "Authorization: Bearer " .. data.token
  local formatted_data = data_formatter(data)
  local args = {
    "https://micro.blog/micropub",
    "-X", "POST",
    "-H", auth_string,
    "-H", "Content-Type: application/json",
    "--data", formatted_data
  }

  local curl_job = job:new({
    command = "curl",
    args = args,
    enable_recording = true
  })

  curl_job:sync()
  local result_raw = curl_job:result()
  local await_post_confirmation = vim.wait(5000, function() return #result_raw > 0 end)
  if await_post_confirmation then
    local result = vim.fn.json_decode(result_raw)
    if result.error then
      print("\nPosting failed: " .. result.error_description)
      return false
    else
      data.opts.url = result.url
      status.set_post_status(data.opts)
      print("\nPost made to " .. result.url)
      return true
    end
  else
    status.set_post_status(data.opts)
    return true
  end
end

local function finalise_post(data)
  local formatter
  if data.opts.url == "" then
    formatter = micropub_new_post_formatter
  else
    formatter = micropub_update_post_formatter
  end

  local confirm = nil
  vim.ui.select({ "Post", "Abort" },
    {
      prompt = "You are about to make a post with the following settings\n" ..
          status.get_post_status_string(data.opts) .. "\n"
    },
    function(choice)
      confirm = (choice == "Post")
    end)

  if confirm then
    send_post_request(data, formatter)
    status.set_post_status(data.opts)
  end
end


function M.push_post()
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
    form.telescope_choose_categories(all_destination_categories, chosen_categories,
      function()
        data.opts.categories = chosen_categories
        finalise_post(data)
      end
    )
  end
end

function M.quick_post()
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
    destination = config.blogs[1].uid,
    url = ""
  }
  finalise_post(data)
end

return M
