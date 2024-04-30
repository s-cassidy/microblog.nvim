local status = require("microblog.status")
local config = require("microblog.config")
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local telescope_conf = require("telescope.config").values
local job = require('plenary.job')

local M = {}

local function get_posts(destination)
  local curl_job = job:new(
    {
      command = "curl",
      args = {
        "https://micro.blog/micropub?q=source&mp-destination=" .. destination,
        "-H", "Authorization: Bearer " .. config.api_key
      },
      enabled_recording = true,
    }
  )
  vim.wait(10, function() return false end, 5)
  curl_job:sync()
  local result_raw = curl_job:result()
  local result = vim.fn.json_decode(result_raw)["items"]
  return result
end


local function format_telescope_entry_string(post)
  local published = post.properties.published[1]
  local post_date = string.sub(published, 1, 10)
  local snippet = post.properties.name[1]
  if snippet == "" then
    local newline_index = string.find(post.properties.content[1], "\n")
    snippet = post.properties.content[1]
    if newline_index then
      snippet = string.sub(snippet, 1, newline_index - 1)
    end
  end
  return post_date .. "  " .. snippet
end


local function open_post(post_text)
  local text_lines = vim.split(post_text, "\n")
  local buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, 0, false, text_lines)
  vim.bo.filetype = "markdown"
end

local function telescope_choose_post(posts, cb)
  local post_picker = pickers.new({}, {
    prompt_title =
    "Select a post",
    finder = finders.new_table({
      results = posts,
      entry_maker = function(entry)
        local display = format_telescope_entry_string(entry)
        return {
          value = entry,
          display = display,
          ordinal = entry.properties.published[1] .. entry.properties.name[1] .. entry.properties.content[1],
        }
      end
    }),
    sorter = telescope_conf.generic_sorter(),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry().value
        actions.close(prompt_bufnr)
        cb(selection)
      end)
      return true
    end
  })
  post_picker:find()
end


function M.pick_post()
  local destination
  local blogs_map = {}
  local blog_urls = {}
  for _, blog in ipairs(config.blogs) do
    blogs_map[blog.url] = blog.uid
    table.insert(blog_urls, blog.url)
  end
  if #config.blogs > 1 then
    vim.ui.select(blog_urls,
      {
        prompt = "Edit post from: ",
      },
      function(input)
        destination = blogs_map[input]
      end)
  else
    destination = config.blogs[1]
  end
  local posts = get_posts(destination)
  if vim.wait(10000, function() return #posts > 0 end, 400) then
    telescope_choose_post(posts, function(selection)
      local props = selection.properties
      open_post(props.content[1])
      status.set_post_status({
        url = props.url[1],
        destination = destination,
        categories = props.category,
        title = props.name[1],
        draft = (props["post-status"][1] == "draft")
      }
      )
    end
    )
  end
end

return M
