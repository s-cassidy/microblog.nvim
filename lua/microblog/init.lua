local config = require("microblog.config")
local get = require("microblog.get")
local post = require("microblog.post")

local function get_api_key()
  return os.getenv(config.api_key_variable)
end

local function setup(opts)
  vim.tbl_extend("force", config, opts)
  config.api_key = get_api_key()
end

return {
  setup = setup,
  pick_post = get.pick_post,
  push_post = post.push_post
}
