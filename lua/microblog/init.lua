local config = require("microblog.config")
local get = require("microblog.get")
local post = require("microblog.post")

local M = {}
M.pick_post = get.pick_post
M.push_post = post.push_post
local function get_api_key()
  return os.getenv(config.api_key_variable)
end

function M.setup(opts)
  vim.tbl_extend("force", config, opts)
  config.api_key = get_api_key()
end

return M
