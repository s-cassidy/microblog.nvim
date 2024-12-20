local M = {}

local function initialise_status()
  return vim.b.micro or {}
end

function M.set_post_status(data)
  local status = initialise_status()
  status.type = "post"
  status.title = data.title
  status.blog_url = data.blog_url
  status.draft = data.draft
  status.categories = data.categories
  status.url = data.url
  vim.b.micro = status
end

function M.set_page_status(data)
  local status = initialise_status()
  status.type = "page"
  status.title = data.title
  status.blog_url = data.blog_url
  status.template = data.template
  status.url = data.url
  vim.b.micro = status
end

---
---@param field string
function M.get_status(field)
  local status = initialise_status()
  if status[field] and #status[field] > 0 then
    return status[field]
  else
    return nil
  end
end

---
---@param data table?
function M.get_page_status_string(data)
  local status = initialise_status()
  local status_for_display = data or status
  if vim.tbl_isempty(status_for_display) then
    return nil
  end
  return ([[Post title: %s
Post url: %s
Destination blog: %s
Path: %s
]]):format(
    status_for_display.title or "",
    status_for_display.blog_url or "",
    status_for_display.path or ""
  )
end

function M.get_status_string()
  if vim.b.micro then
    print(vim.b.micro:get_status_string())
  end
end

function M.reset_post_status()
  vim.b.micro = nil
end

function M.display_post_status()
  local status_for_display
  if vim.b.micro then
    status_for_display = vim.b.micro:get_status_string()
  end
  if status_for_display == nil then
    vim.notify("Does not seem to be a micro.blog entry")
    return
  end
  vim.notify("micro.blog post information\n" .. status_for_display)
end

return M
