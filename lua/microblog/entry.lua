local curl = require("plenary.curl")
local config = require("microblog.config")

local Entry = {}

function Entry:new(buffer_data)
  local entry = buffer_data or {}
  setmetatable(entry, Entry)
  self.__index = self
  return entry
end

--- Get contents of a buffer or lines appearing in a visual selection
---
--- @return string
function Entry:get_text()
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
    if vim.fn.mode() == "v" then
      content_lines = vim.api.nvim_buf_get_text(
        0,
        visual_start[2] - 1,
        visual_start[3] - 1,
        visual_end[2] - 1,
        visual_end[3],
        {}
      )
    else
      content_lines = vim.api.nvim_buf_get_lines(0, visual_start[2] - 1, visual_end[2], false)
    end
  end
  local text = table.concat(content_lines, "\n")
  return text
end

function Entry:publish_setup()
  self.token = config.app_token
  if self.token == nil then
    print("No app token found")
    return
  end
  local opts = self:collect_user_options()
end

--- Run curl to post to the blog
--- @param data {text: string, token: string, opts: {title: string?, blog_url: string, draft: boolean, url: string?, categories: string[]?}}
--- @param data_formatter function
--- @return boolean
function Entry:send_post_request()
  local auth_string = "Bearer " .. config.app_token
  local formatted_data = self:formatter()

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

  local response_url
  for _, header in ipairs(response.headers) do
    if string.match(header, "location: ") then
      response_url = string.gsub(header, "location: ", "")
    end
  end

  if response_url ~= self.url then
    if response.status == 202 then
      print("\nPost made to " .. response_url)
    elseif response.status == 201 then
      print("\nPost url updated to " .. response_url)
    end
  else
    print("\nPost successfully updated")
  end

  self.url = response_url
  return true
end

return Entry
