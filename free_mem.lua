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

return M 

