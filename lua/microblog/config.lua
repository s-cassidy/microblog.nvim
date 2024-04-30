local config = {
  api_key_variable = "MB_API_KEY",
  blogs = {
  }
}

local function read_api_key()
  return os.getenv(config.api_key_variable)
end

local mt = {}

setmetatable(config, mt)

mt.__index = function(table, key)
  if key == "api_key" then
    local api_key = read_api_key()
    if #api_key > 0 then
      return api_key
    else
      return nil
    end
  else
    return table[key]
  end
end

return config
