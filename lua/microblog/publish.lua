local curl = require("plenary.curl")
local status = require("microblog.status")
local form = require("microblog.form")
local util = require("microblog.util")
local categories = require("microblog.categories")
local config = require("microblog.config")
local Post = require("microblog.post")
local Page = require("microblog.page")

local M = {}



function M.publish()
  local entry
  if vim.b.micro then
    if vim.b.micro.type == "post" then
      entry = Post:new(vim.b.micro)
    elseif vim.b.micro.type == "page" then
      entry = Page:new(vim.b.micro)
    end
  else
    entry = Post:new()
  end
  local success = entry:publish()
  if success then
    vim.b.micro = entry
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
    blog_url = config.blogs[1].url,
    url = "",
  }
  local result = finalise_post(data)
  if result and config.no_save_quickpost then
    vim.bo.buftype = "nowrite"
  end
end

return M
