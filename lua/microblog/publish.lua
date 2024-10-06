local curl = require("plenary.curl")
local status = require("microblog.status")
local form = require("microblog.form")
local util = require("microblog.util")
local categories = require("microblog.categories")
local config = require("microblog.config")
local Post = require("microblog.post")

local M = {}



function M.publish()
  if vim.b.micro then
    vim.b.micro.publish()
  else
    local post = Post:new()
    post:publish()
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
