local lgi = require("lgi")
local GTop = lgi.require("GTop")
local UPowerGlib = lgi.require("UPowerGlib")

local M = {} 

GTop.glibtop_init()

local battery_cache = nil
local battery_cache_time = 0

function M.get_mem_info()
  local mem = GTop.glibtop_mem()
  local swap = GTop.glibtop_swap()

  GTop.glibtop_get_mem(mem)
  GTop.glibtop_get_swap(swap)

  local function to_mb(bytes)
    return bytes / (1024 * 1024)
  end

  return {
    ram = {
      total = to_mb(mem.total),
      used = to_mb(mem.used),
      free = to_mb(mem.free),
      percent_used = (mem.used / mem.total) * 100
    },
    swap = {
      total = to_mb(swap.total),
      used = to_mb(swap.used),
      free = to_mb(swap.free),
      percent_used = swap.total > 0 and (swap.used / swap.total) * 100 or 0
    }
  }
end 

function M.get_disk_usage(point)
  local fs_usage = GTop.glibtop_fsusage()
  GTop.glibtop_get_fsusage(fs_usage, point)
  
  if fs_usage.blocks > 0 then
    local percent = (fs_usage.blocks - fs_usage.bavail) * 100 / fs_usage.blocks
    return percent
  end
  return 0
end

function M.get_battery_info()
  -- Usar caché si tiene menos de 5 segundos
  local current_time = os.time()
  if battery_cache and (current_time - battery_cache_time) < 5 then
    return battery_cache
  end

  local client = UPowerGlib.Client.new()
  for _, device in pairs(client:get_devices()) do 
    if device:get_object_path() == "/org/freedesktop/UPower/devices/battery_BAT0" then
      battery_cache = {
        percentage = device.percentage,
        state = device.state,
        time_empty = device.time_to_empty,
        time_full = device.time_to_full
      }
      battery_cache_time = current_time
      return battery_cache
    end
  end
  
  -- Valores por defecto si no se encuentra batería
  return {
    percentage = 0,
    state = 0,
    time_empty = 0,
    time_full = 0
  }
end

function M.get_battery_percentage()
  local info = M.get_battery_info()
  return info.percentage
end

function M.get_battery_state()
  local info = M.get_battery_info()
  return tonumber(info.state)
end

-- Últimos valores para cálculo de CPU
local last_total = 0 
local last_idle = 0

function M.get_cpu_used()
  local cpu = GTop.glibtop_cpu()
  GTop.glibtop_get_cpu(cpu)

  if last_total > 0 and last_idle > 0 then 
    local total_diff = cpu.total - last_total
    local idle_diff = cpu.idle - last_idle
    if total_diff > 0 then
      local usage = 100 * (1 - (idle_diff / total_diff))
      last_total = cpu.total
      last_idle = cpu.idle
      return math.min(100, math.max(0, usage))
    end
  end
  
  last_total = cpu.total
  last_idle = cpu.idle
  return 0
end

return M