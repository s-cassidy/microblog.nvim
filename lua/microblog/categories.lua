local job = require("plenary.job")
local config = require("microblog.config")

local M = {}
local raw_list = {}


--- Take the /categories/feed.json server response and extract categories
---@param json_feed string
---@return string[]
local function extract_categories_from_json_feed(json_feed)
  local categories_table = {}
  local success, feeds_table = pcall(vim.fn.json_decode, json_feed)
  if not success then
    return {}
  end
  for _, item in pairs(feeds_table.items) do
    table.insert(categories_table, item.title)
  end
  return categories_table
end


--- Run curl to get the categories from a blog
---@param blog {url: string, uid: string}
local function fetch_categories(blog)
  local category_job = job:new({
    command = "curl",
    args = { blog.url .. "/categories/feed.json" },
    enable_recording = true,
    on_exit = function(j)
      raw_list[blog.uid] = j:result()
    end
  })
  category_job:start()
end


function M.refresh_categories()
  for _, blog in ipairs(config.blogs) do
    fetch_categories(blog)
  end
end

--- Return parsed categories list
---@param uid string
---@return string[]
function M.get_categories(uid)
  return extract_categories_from_json_feed(raw_list[uid])
end

return M
