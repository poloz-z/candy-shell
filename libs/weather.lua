-- libs/weather.lua
local lgi = require('lgi')
local GWeather = lgi.GWeather
local GLib = lgi.GLib

local M = {}

M.datos = {
  load = false,
  state = "state",
  country = "country",
  temp = 0,
  descrip = 0,
  icon = nil,
  emoji = nil,
  wind = nil,
  humi = nil
}

local icons_emoji = {
  ["weather-clear"]             = "󰖙", 
  ["weather-few-clouds"]        = "󰖕", 
  ["weather-clouds"]            = "󰖐", 
  ["weather-overcast"]          = "󰖐", 
  ["weather-showers"]           = "󰖗", 
  ["weather-showers-scattered"] = "󰖗",
  ["weather-rain"]              = "󰖖", 
  ["weather-storm"]             = "󰖓", 
  ["weather-snow"]              = "󰼶", 
  ["weather-fog"]               = "󰖑", 
}

local current_info = nil

function M.update(seconds, callback)
  local mundo = GWeather.Location.get_world()
  local caracas = mundo:find_nearest_city(10.48, -66.90)  -- edit con tu ciudad

  if not caracas then return false, "not found" end

  if current_info then
    current_info = nil
  end

  local info = GWeather.Info.new()
  current_info = info -- Guardar referencia para gestionar ciclo de vida

  info:set_location(caracas)
  info:set_application_id("io.github.poloz_z.CandyShell.Lua.Gtk4.Shell")
  info:set_contact_info("jpolo5678@gmail.com") 
  info:set_enabled_providers("MET_NO")

  local loop = GLib.MainLoop()
  local success = false

  info.on_updated = function(self)
    M.datos.state = caracas:get_city_name()
    M.datos.country = caracas:get_country_name()
    
    M.datos.temp = self:get_temp()
    M.datos.descrip = self:get_conditions()
    M.datos.wind = self:get_wind()
    M.datos.humi = self:get_humidity()
    
    local icon_name = self:get_icon_name()
    M.datos.icon = icon_name
    M.datos.emoji = icons_emoji[icon_name] or ""
    
    M.datos.load = true
    success = true
    loop:quit()
  end

  info:update()

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, seconds or 10, function()
    if not success then
      loop:quit()
    end
    return false
  end)

  loop:run()

  if callback and success then
    callback(M.datos)
  end

  mundo = nil
  caracas = nil

  return success
end

return M