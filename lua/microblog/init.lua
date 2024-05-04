local config = require("microblog.config")
local get = require("microblog.get")
local post = require("microblog.post")
local status = require("microblog.status")

local M = {}
M.pick_post = get.pick_post
M.get_post_from_url = get.get_post_from_url
M.publish = post.publish
M.quick_post = post.quickpost
M.display_post_status = status.display_post_status
M.reset_post_status = status.reset_post_status

vim.api.nvim_create_user_command(
  "MicroBlogPickPost",
  get.pick_post,
  { desc = "Pick a blog post from the server using Telescope" }
)
vim.api.nvim_create_user_command(
  "MicroBlogQuickPost",
  post.quickpost,
  { desc = "Quickly send a blog post with default settings" }
)
vim.api.nvim_create_user_command(
  "MicroBlogPostFromUrl",
  get.get_post_from_url,
  { desc = "Edit a blog post by entering its url" }
)
vim.api.nvim_create_user_command("MicroBlogPublish", post.publish, { desc = "Publish or update blog post" })
vim.api.nvim_create_user_command(
  "MicroBlogDisplayStatus",
  status.display_post_status,
  { desc = "Show micro.blog status of current buffer" }
)
vim.api.nvim_create_user_command(
  "MicroBlogResetStatus",
  status.reset_post_status,
  { desc = "Reset blog metadata for current buffer" }
)

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
