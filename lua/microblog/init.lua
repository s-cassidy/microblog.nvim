local config = require("microblog.config")
local get = require("microblog.get")
local post = require("microblog.post")
local status = require("microblog.status")

local M = {}
M.pick_post = get.pick_post
M.push_post = post.push_post
M.quick_post = post.quick_post
M.display_post_status = status.display_post_status
M.reset_post_status = status.reset_post_status

vim.api.nvim_create_user_command("MicroBlogPickPost", get.pick_post, {})
vim.api.nvim_create_user_command("MicroBlogQuickPost", post.quick_post, {})
vim.api.nvim_create_user_command("MicroBlogPushPost", post.push_post, {})
vim.api.nvim_create_user_command("MicroBlogDisplayStatus", status.display_post_status, {})
vim.api.nvim_create_user_command("MicroBlogResetStatus", status.reset_post_status, {})

local function get_api_key()
  return os.getenv(config.api_key_variable)
end

function M.setup(opts)
  config.api_key_variable = config.api_key_variable or opts.api_key_variable
  config.blogs = opts.blogs
  config.api_key = get_api_key()
end

return M
