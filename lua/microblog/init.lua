local config = require("microblog.config")
local categories = require("microblog.categories")
local get = require("microblog.get")
local post = require("microblog.post")
local async = require("plenary.async.async")

local M = {}
M.pick_post = get.pick_post
M.push_post = post.push_post

function M.setup(opts)
  config.api_key_variable = config.api_key_variable or opts.api_key_variable
  config.blogs = opts.blogs
end

return M
