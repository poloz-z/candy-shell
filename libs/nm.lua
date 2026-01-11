-- libs/nm.lua
local M = {}

local lgi = require("lgi")
local NM = lgi.require("NM")
local GLib = lgi.require("GLib")

-- Cliente singleton
local nm_client = nil
local function get_client()
  if not nm_client then
    nm_client = NM.Client.new()
  end
  return nm_client
end

-- Convertir SSID a texto
local function ssid_to_text(ssid_bytes)
  if not ssid_bytes then 
    return "oculta" 
  end
  local text = ssid_bytes:get_data()
  return text or "uknow"
end

-- Obtener dispositivo WiFi
local function get_wifi_device()
  local client = get_client()
  if not client then return nil end

  local devices = client:get_devices() or {}
  for _, dev in ipairs(devices) do
    if tostring(dev:get_device_type()) == "WIFI" then
      return dev
    end
  end
  return nil
end

function M.get_wifi_info()
  local wifi_dev = get_wifi_device()
  if not wifi_dev then 
    return { error = "no se encontro dispositivo wifi" }
  end

  local active_ap = wifi_dev:get_active_access_point()
  local current_status = {
    interface = wifi_dev:get_iface(),
    state = wifi_dev.state,
    ssid = "desconectado",
    strength = 0,
    connected = false
  }

  if active_ap then
    local ssid_bytes = active_ap:get_ssid()
    if ssid_bytes then
      current_status.ssid = ssid_to_text(ssid_bytes)
      current_status.strength = active_ap:get_strength()
      current_status.connected = true
    end
  end

  wifi_dev = nil
  return current_status
end

function M.get_wifi_strength()
  local info = M.get_wifi_info()
  if info.error or not info.connected then
    return 0
  end
  return info.strength
end

function M.is_wifi_connected()
  local info = M.get_wifi_info()
  return not info.error and info.connected
end

return M