local status = require("microblog.status")
local form = require("microblog.form")
local config = require("microblog.config")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local telescope_conf = require("telescope.config").values
local util = require("microblog.util")
local curl = require("plenary.curl")

local M = {}

local function make_source_request(blog_url, url)
  local response = curl.get("https://micro.blog/micropub", {
    headers = {
      authorization = "Bearer " .. config.app_token,
    },
    query = {
      q = "source",
      ["mp-destination"] = util.url_to_uid(blog_url) or "",
      url = url or "",
    },
    timeout = 10000,
  })

  local result_raw = response.body
  if response.status == 400 then
    vim.notify("Bad request. Did you set your blog's UID correctly?")
    return
  end
  if response.status == 200 then
    local result = vim.fn.json_decode(result_raw)
    if vim.tbl_isempty(result) then
      vim.notify("Server sent an empty response. Did you set your app token correctly?")
    end
    return result
  end
end

local function get_post_list(blog_url)
  return make_source_request(blog_url, "")["items"]
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

local function open_post(post_json, blog_url)
  local post_text = post_json.content[1]
  local text_lines = vim.split(post_text, "\n")
  local buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, 0, false, text_lines)
  vim.bo.filetype = "markdown"
  status.set_post_status({
    url = post_json.url[1],
    blog_url = blog_url,
    categories = post_json.category,
    title = post_json.name[1],
    draft = (post_json["post-status"][1] == "draft"),
  })
end

local function telescope_choose_post(posts, cb)
  local post_picker = pickers.new({}, {
    prompt_title = "Select a post",
    finder = finders.new_table({
      results = posts,
      entry_maker = function(entry)
        local display = format_telescope_entry_string(entry)
        return {
          value = entry,
          display = display,
          ordinal = entry.properties.published[1] ..
              entry.properties.name[1] .. entry.properties.content[1] .. entry.properties.url[1],
        }
      end,
    }),
    sorter = telescope_conf.generic_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry().value
        actions.close(prompt_bufnr)
        cb(selection)
      end)
      map("i", "<CR>", actions.select_default)
      map("n", "<CR>", actions.select_default)
      map("n", "<esc>", actions.close)
      map("n", "q", actions.close)
      map("n", "<C-c>", actions.close)
      map("i", "<up>", actions.move_selection_previous)
      map("i", "<down>", actions.move_selection_next)
      map("i", "<C-p>", actions.move_selection_previous)
      map("i", "<C-n>", actions.move_selection_next)
      map("n", "<up>", actions.move_selection_previous)
      map("n", "<down>", actions.move_selection_next)
      return false
    end,
  })
  post_picker:find()
end

local function capture_destination(url)
  local _, _, destination = url:find("(https?://.-/)")
  return destination
end

function M.get_post_from_url(url)
  if url and url ~= "" then
    local blog_url = capture_destination(url)
    local result = make_source_request(blog_url, url)
    if result then
      open_post(result.properties, blog_url)
    end
  else
    vim.ui.input({
      prompt = "url: ",
    }, function(input)
      local blog_url = capture_destination(input)
      local result = make_source_request(blog_url, input)
      if result then
        open_post(result.properties, blog_url)
      end
    end)
    return
  end
end

function M.pick_post()
  if config.app_token == nil then
    print("No app token found")
    return
  end
  local blog_url = form.choose_blog_url("get")
  local posts = get_post_list(blog_url)
  if vim.wait(10000, function()
        return #posts > 0
      end, 400) then
    telescope_choose_post(posts, function(selection)
      open_post(selection.properties, blog_url)
    end)
  end
end

return M
