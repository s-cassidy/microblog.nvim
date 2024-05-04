local config = require("microblog.config")
local status = require("microblog.status")
M = {}

function M.choose_destination(mode)
  if mode == "post" and status.get_status("destination") then
    return status.get_status("destination")
  end

  local destination
  local urls_list = {}
  local urls_map = {}
  for _, blog in ipairs(config.blogs) do
    table.insert(urls_list, blog.url)
    urls_map[blog.url] = blog.uid
  end

  if #config.blogs > 1 then
    vim.ui.select(urls_list, {
      prompt = (mode == "post" and "Destination: ") or "Edit post from: ",
    }, function(input)
      destination = urls_map[input]
    end)
  else
    destination = config.blogs[1].uid
  end

  return destination
end

return M
