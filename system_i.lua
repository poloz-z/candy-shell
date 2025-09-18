lgi = require("lgi")
GTop = lgi.require("GTop")

local M = {} 

GTop.glibtop_init()

function M.get_mem_info()
  local mem = GTop.glibtop_mem()
  local swap = GTop.glibtop_swap()

  GTop.glibtop_get_mem(mem)
  GTop.glibtop_get_swap(swap)

  local function to_mb(bytes)
    return bytes/(1024*1024)
  end

  return {
    ram = {
      total = to_mb(mem.total),
      used = to_mb(mem.used),
      free = to_mb(mem.free),
      shared = to_mb(mem.shared),
      buffer = to_mb(mem.buffer),
      cached = to_mb(mem.cached),
      percent_used = (mem.used/mem.total)*100
    },
    swap = {
      total = to_mb(swap.total),
      used = to_mb(swap.used),
      free = to_mb(swap.free),
      percent_used = (swap.used/swap.total)*100
    }
  }
end 

function M.get_mem_usage()
  local info = M.get_mem_info()
  return info.ram.percent_used 
end

function M.get_swap_usage()
  local info = M.get_mem_info()
  return info.swap.percent_used 
end

function M.get_mem_free()
  local info = M.get_mem_info()
  return info.ram.free
end

function M.get_swap_free()
  local info = M.get_mem_info()
  return info.swap.free
end

local last_total = 0 
local last_idle = 0
function M.get_cpu_used()
  local cpu = GTop.glibtop_cpu()
  GTop.glibtop_get_cpu(cpu)

  if last_total > 0 and last_idle > 0 then 
    local total_diff = cpu.total - last_total
    local idle_diff = cpu.idle - last_idle
    if total_diff > 0 then
      local usage = 100*(1-(idle_diff/total_diff))
      last_total = cpu.total
      last_idle = cpu.idle
      return math.min(100, math.max(0, usage))
    end
  end
  last_total = cpu.total
  last_idle = cpu.idle
  return 0
end


function M.get_df_info(mount)
  local to_gb = 1024^3
  local buf = GTop.glibtop_fsusage()
  GTop.glibtop_get_fsusage(buf,mount)
  return {
    size  = math.floor((buf.blocks*buf.block_size)/to_gb),
    used  = math.floor(((buf.blocks-buf.bavail)*buf.block_size)/to_gb),
    free  = math.floor((buf.bfree * buf.block_size)/to_gb),
    avail = math.floor((buf.bavail * buf.block_size)/to_gb)
  }
end

return M 

