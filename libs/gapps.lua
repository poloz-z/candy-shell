-- libs/gapps.lua
-- minimal utils apps info
local lgi = require('lgi')
local Gio = lgi.require('Gio')

M = {}

function M.get_all_apps()
  local apps = {}
  for _, app_info in ipairs(Gio.AppInfo.get_all()) do
    local id = app_info:get_id()
    apps[id] = {
      obj = app_info,
      name = app_info:get_display_name(),
      description = app_info:get_description() or 'nil',
      icon = app_info:get_icon(), 
      launch = function() app_info:launch({}, nil) end
    }
  end
  return apps
end


return M