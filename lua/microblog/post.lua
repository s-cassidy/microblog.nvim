local job = require('plenary.job')
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
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { vim.fn.json_encode(json_data) })
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
--- @param data {text: string, key: string, opts: {title: string?, destination: string, draft: boolean, url: string?, categories: string[]?}}
--- @return boolean
local function send_post_request(data, data_formatter)
  local auth_string = "Authorization: Bearer " .. data.key
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
      print("Posting failed: " .. result.error_description)
      return false
    else
      vim.b.micro = result
      print("New post made to " .. result.url)
      return true
    end
  else
    return false
  end
end

function M.push_post()
  vim.b.micro = vim.b.micro or {}

  -- start getting categories from the server first to reduce waiting later
  local categories_table = {}
  for _, blog in ipairs(config.blogs) do
    categories_table[blog.uid] = categories.get_categories(blog.url)
  end

  local formatter
  local data = {}
  data.text = get_text()
  data.key = config.key
  data.opts = form.collect_user_options()
  if data.opts.url == "" then
    formatter = micropub_new_post_formatter
  else
    formatter = micropub_update_post_formatter
  end

  local chosen_categories = {}
  vim.notify("Awaiting categories list")
  if vim.wait(5000, function()
        return (#categories_table[data.opts.destination] > 0 or categories_table == nil)
      end, 400) then
    local all_destination_categories = categories_table[data.opts.destination]
    form.telescope_choose_categories(all_destination_categories, chosen_categories,
      function()
        data.opts.categories = chosen_categories
        send_post_request(data, formatter)
      end
    )
  end
end

return M
