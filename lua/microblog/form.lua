local config = require("microblog.config")
local status = require("microblog.status")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local telescope_conf = require("telescope.config").values

local M = {}

function M.telescope_choose_categories(all_categories, chosen_categories, cb)
  local existing_categories = status.get_status("categories") or {}
  local startup_complete = false
  local cat_picker = pickers.new({}, {
    prompt_title =
    "Select categories (Use <tab> to select categories, <CR> to confirm selection. Quit this window to abort)",
    finder = finders.new_table({ results = all_categories }),
    sorter = telescope_conf.generic_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        for _, selection in ipairs(current_picker:get_multi_selection()) do
          table.insert(chosen_categories, selection[1])
        end
        actions.close(prompt_bufnr)
        cb()
      end)
      map("i", "<CR>", actions.select_default)
      map("n", "<CR>", actions.select_default)
      map("i", "<tab>", actions.toggle_selection)
      map("n", "<tab>", actions.toggle_selection)
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
    on_complete = {
      -- Preselect categories already set on the blog post
      function(picker)
        if startup_complete then
          return
        end

        for entry in picker.manager:iter() do
          if vim.tbl_contains(existing_categories, entry[1]) then
            local row = picker:get_row(entry.index)
            picker:add_selection(row)
          end
        end
        startup_complete = true
      end,
    },
  })
  cat_picker:find()
end

--- Pick the post title
---@return string
function M.choose_title()
  local title
  vim.ui.input({
    prompt = "Post title (optional): ",
    default = status.get_status("title") or "",
  }, function(input)
    title = input
  end)
  return title
end

--- Pick an url to post to
---@return string
function M.choose_url()
  local url
  if config.always_input_url then
    vim.ui.input({
      prompt = "Post url (leave blank for new post): ",
      default = status.get_status("url") or "",
    }, function(input)
      url = input
    end)
  else
    url = status.get_status("url") or ""
    if url == "" then
      return url
    end
    local options = { "Update " .. url, "New post" }
    vim.ui.select(options, {}, function(input)
      if input == options[2] then
        url = ""
      end
    end)
  end
  return url
end

function M.choose_blog_url(mode)
  if mode == "post" and status.get_status("blog_url") then
    return status.get_status("blog_url")
  end

  local blog_url
  local urls_list = {}
  for _, blog in ipairs(config.blogs) do
    table.insert(urls_list, blog.url)
  end

  if #config.blogs > 1 then
    vim.ui.select(urls_list, {
      prompt = (mode == "post" and "Post to: ") or "Edit post from: ",
    }, function(input)
      blog_url = input
    end)
  else
    blog_url = config.blogs[1].url
  end

  return blog_url
end

--- Should post be made as a draft?
---@return boolean
function M.choose_draft()
  local draft
  vim.ui.select({ "Yes", "No" }, {
    prompt = "\nPost as a draft?",
  }, function(choice)
    draft = (choice == "Yes")
  end)
  return draft
end

function M.collect_post_options()
  local opts_table = {}
  opts_table.blog_url = choose_blog_url("post")
  opts_table.title = choose_title()
  opts_table.url = choose_url()
  opts_table.draft = choose_draft()
  return opts_table
end

function M.collect_page_options()
  local opts_table = {}
  opts_table.blog_url = choose_blog_url("post")
  opts_table.title = choose_title()
  return opts_table
end

return M
