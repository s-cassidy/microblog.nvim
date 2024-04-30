local M = {}

local function load_status()
  return vim.b.micro or {}
end

function M.set_post_status(data)
  local status = load_status()
  status.title = data.title
  status.destination = data.destination
  status.draft = data.draft
  status.categories = data.categories
  status.url = data.url
  vim.b.micro = status
end

function M.get_status(field)
  local status = load_status()
  if (status[field] and #status[field] > 0) then
    return status[field]
  else
    return nil
  end
end

---
---@param data table?
function M.get_post_status_string(data)
  local status = load_status()
  local status_for_display = data or status
  if vim.tbl_isempty(status_for_display) then
    return nil
  end
  local categories_string = table.concat(status_for_display.categories, ", ")
  return ([[Post title: %s
Post url: %s
Desintation blog: %s
Categories: %s
Draft: %s]]):format(
    status_for_display.title or "",
    status_for_display.url or "New post",
    status_for_display.destination or "",
    categories_string or "",
    (status_for_display.draft and "Yes") or "No"
  )
end

function M.reset_post_status()
  vim.b.micro = {}
end

function M.display_post_status()
  local status_for_display = M.get_post_status_string()
  if status_for_display == nil then
    vim.notify("Does not seem to be a micro.blog post")
    return
  end
  vim.notify("micro.blog post information\n" .. status_for_display)
end

return M
