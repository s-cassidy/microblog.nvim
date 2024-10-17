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
    replace = {
      name = { self.title or "" },
      ["page-status"] = { (self.draft and "draft") or "published" },
      content = { self.text },
      category = self.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

--- Takes page data and formats body for a micropub create action
---@return string
function Page:micropub_new_formatter()
  local json_data = {
    type = { "h-entry" },
    ["mp-destination"] = util.url_to_uid(self.blog_url),
    properties = {
      content = { { html = self.text } },
      name = { (self.title or "") },
      ["page-status"] = { (self.draft and "draft" or "published") },
      category = self.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

function Page:get_status_string()
  local categories_string = table.concat(self.categories, ", ")
  return ([[Page title: %s
Page url: %s
Destination blog: %s
Categories: %s
Draft: %s]]):format(
    self.title or "",
    (self.url == "" and "New page") or self.url,
    self.blog_url or "",
    categories_string or "",
    (self.draft and "Yes") or "No"
  )
end

function Page:finalise()
  local confirm = nil
  if self.url == "" then
    self.formatter = self.micropub_new_formatter
  else
    self.formatter = self.micropub_update_formatter
  end
  local status_string = self:get_status_string()
  vim.ui.select({ "Page", "Abort" }, {
    prompt = "You are about to make a page with the following settings\n"
        .. status_string
        .. "\n",
  }, function(choice)
    confirm = (choice == "Page")
  end)

  if not confirm then
    return false
  end

  return true
end

function Page:collect_user_options()
  self.blog_url = form.choose_blog_url("page")
  self.title = form.choose_title()
  self.url = form.choose_url()
  self.draft = form.choose_draft()
end

function Page:setup()
  self.text = self:get_text()
  self:collect_user_options()
end

function Page:publish()
  categories.refresh_categories()
  self:setup()
  local chosen_categories = {}
  local all_blog_url_categories = categories.get_categories(self.blog_url)
  if vim.tbl_isempty(all_blog_url_categories) then
    print("\nNo categories found for " .. self.blog_url)
    self.categories = chosen_categories
    if self:finalise() then
      local success = self:send_post_request()
      if success then
        vim.b.micro = self
      end
    end
  else
    form.telescope_choose_categories(all_blog_url_categories, chosen_categories, function()
      self.categories = chosen_categories
      if self:finalise() then
        local success = self:send_post_request()
        if success then
          vim.b.micro = self
        end
      end
    end)
  end
end

return Page
