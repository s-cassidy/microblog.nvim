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

local function get_app_token()
  return os.getenv(config.app_token_variable)
end

function M.setup(opts)
  config.app_token_variable = opts.app_token_variable or config.app_token_variable
  config.blogs = opts.blogs
  config.always_input_url = opts.always_input_url or config.always_input_url
  config.no_save_quickpost = opts.no_save_quickpost or config.no_save_quickpost
  config.app_token = get_app_token()
  config.token_warn_on_startup = opts.token_warn_on_startup or config.token_warn_on_startup

  if config.token_warn_on_startup then
    if not config.app_token then
      vim.schedule(function()
        print("Warning: no MicroBlog app token found")
      end)
    end
  end
end

return M
