local categories = require("microblog.categories")
local Entry = require("microblog.entry")
local form = require("microblog.form")
local util = require("microblog.util")


local Page = Entry:new()

function Page:new(buffer_data)
  local page = buffer_data or {}
  setmetatable(page, Page)
  self.__index = self
  page.type = "page"
  return page
end

--- Takes page data and formats body for a micropub replace action
---@param data table
---@return string
function Page:micropub_update_formatter(data)
  local json_data = {
    action = "update",
    url = self.url,
    ["mp-destination"] = util.url_to_uid(self.blog_url),
    ["mp-channel"] = "page",
    replace = {
      name = { self.title or "" },
      content = { self.text },
    },
  }
  return vim.fn.json_encode(json_data)
end

function Page:get_status_string()
  return ([[Page title: %s
Page url: %s
Destination blog: %s]]):format(
    self.title or "",
    self.url,
    self.blog_url or ""
  )
end

function Page:finalise()
  local confirm = nil
  self.formatter = self.micropub_update_formatter
  local status_string = self:get_status_string()
  vim.ui.select({ "Post", "Abort" }, {
    prompt = "You are about to update a page with the following settings\n"
        .. status_string
        .. "\n",
  }, function(choice)
    confirm = (choice == "Post")
  end)

  if not confirm then
    return false
  end

  return true
end

function Page:collect_user_options()
  self.blog_url = form.choose_blog_url("post")
  self.title = form.choose_title()
end

function Page:setup()
  self.text = self:get_text()
  self:collect_user_options()
end

function Page:publish()
  self:setup()
  if self:finalise() then
    local response = self:send_post_request()
    if response.status == 200 then
      vim.b.micro = self
      print("\nPage successfully updated")
    end
  end
end

return Page
