local categories = require("microblog.categories")
local Entry = require("microblog.entry")
local form = require("microblog.form")
local util = require("microblog.util")
local config = require("microblog.config")


local Post = Entry:new()

function Post:new(buffer_data)
  local post = buffer_data or {}
  setmetatable(post, Post)
  self.__index = self
  post.type = "post"
  return post
end

--- Takes post data and formats body for a micropub replace action
---@param data table
---@return string
function Post:micropub_update_formatter(data)
  local json_data = {
    action = "update",
    url = self.url,
    ["mp-destination"] = util.url_to_uid(self.blog_url),
    replace = {
      name = { self.title or "" },
      ["post-status"] = { (self.draft and "draft") or "published" },
      content = { self.text },
      category = self.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

--- Takes post data and formats body for a micropub create action
---@return string
function Post:micropub_new_formatter()
  local json_data = {
    type = { "h-entry" },
    ["mp-destination"] = util.url_to_uid(self.blog_url),
    properties = {
      content = { { html = self.text } },
      name = { (self.title or "") },
      ["post-status"] = { (self.draft and "draft" or "published") },
      category = self.categories,
    },
  }
  return vim.fn.json_encode(json_data)
end

function Post:get_status_string()
  local categories_string = table.concat(self.categories, ", ")
  return ([[Post title: %s
Post url: %s
Destination blog: %s
Categories: %s
Draft: %s]]):format(
    self.title or "",
    (self.url == "" and "New post") or self.url,
    self.blog_url or "",
    categories_string or "",
    (self.draft and "Yes") or "No"
  )
end

function Post:finalise()
  local confirm = nil
  if self.url == "" then
    self.formatter = self.micropub_new_formatter
  else
    self.formatter = self.micropub_update_formatter
  end
  local status_string = self:get_status_string()
  vim.ui.select({ "Post", "Abort" }, {
    prompt = "You are about to make a post with the following settings\n"
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

function Post:collect_user_options()
  self.blog_url = form.choose_blog_url("post")
  self.title = form.choose_title()
  self.url = form.choose_url()
  self.draft = form.choose_draft()
end

function Post:setup()
  self.text = self:get_text()
  self:collect_user_options()
end

function Post:publish()
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
        local response = self:send_post_request()
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
        vim.b.micro = self
      end
    end)
  end
end

function Post:quickpost()
  self.formatter = self.micropub_new_formatter
  self.title = ""
  self.draft = false
  self.categories = {}
  self.blog_url = config.blogs[1].url
  self.url = ""
  self.text = self:get_text()
  local response = self:send_post_request()
  local response_url
  for _, header in ipairs(response.headers) do
    if string.match(header, "location: ") then
      response_url = string.gsub(header, "location: ", "")
    end
  end
  if response_url ~= self.url then
    if response.status == 202 then
      print("QuickPost successful")
      self.url = response_url
      vim.b.micro = self
    end
  end
end

return Post
