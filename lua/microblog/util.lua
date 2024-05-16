local config = require("microblog.config")
local M = {}


function M.url_to_uid(url)
  for _, blog in ipairs(config.blogs) do
    if blog.url == url then
      return blog.uid
    end
  end
  return false
end

return M
