local config = require("microblog.config")
local job = require("plenary.job")

local function fetch_categories(blog_url)
  local category_job = job:new({
    command = "curl",
    args = { blog_url .. "/categories/feed.json" },
    enable_recording = true,
  })
  category_job:start()
  return category_job:result()
end


local function extract_categories_from_json_feed(json_feed)
  local categories_table = {}
  local feeds_table = vim.fn.json_decode(json_feed)
  for _, item in pairs(feeds_table.items) do
    table.insert(categories_table, item.title)
  end
  return categories_table
end


local function get_categories(url)
  local categories_json = fetch_categories(url)
  local await_categories_feed = vim.wait(5000, function() return #categories_json > 0 end)
  if await_categories_feed then
    config.categories = extract_categories_from_json_feed(categories_json)
  else
    config.categories = nil
    print("No categories found at " .. url .. "/categories/feed.json")
  end
end

return {
  get_categories
}
