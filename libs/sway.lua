-- sway-ipc
-- Módulo de IPC de Sway con parseo de JSON automático.
local lgi = require('lgi')
local Gio = lgi.Gio
local Json = lgi.Json

local M = {}

local ffi = require('ffi') 

-- el header de i3/sway es: "i3-ipc" (6 bytes) + length (u32) + type (u32)
ffi.cdef[[
  typedef struct {
    uint32_t length;
    uint32_t type;
  } sway_ipc_header_t;
]]

local IPC_MAGIC = "i3-ipc"
local HEADER_SIZE = 14 -- 6 bytes (magic) + 4 (length) + 4 (type)

M.COMMAND = 0
M.GET_WORKSPACES = 1
M.GET_OUTPUTS = 3
M.GET_TREE = 4
M.GET_VERSION = 7

-------------------------------------

function M.connect()
  local path = os.getenv("SWAYSOCK")
  if not path then 
    return nil 
  end
  local client = Gio.SocketClient.new()
  local addr = Gio.UnixSocketAddress.new(path)
  return client:connect(addr, nil)
end

function M.send_raw(conn, command, msg_type)
  msg_type = msg_type or M.COMMAND
    
  local output = conn:get_output_stream()
  local input = conn:get_input_stream()
    
  -- usar mejor string.pack para lua5.3 > 
  local header_struct = ffi.new("sway_ipc_header_t")
  header_struct.length = #command
  header_struct.type = msg_type
    
  --estructura a un puntero de bytes
  local header_bytes = ffi.cast("char*", header_struct)

  output:write(IPC_MAGIC, nil) 
    
  output:write(ffi.string(header_bytes, ffi.sizeof(header_struct)), nil)

  output:write(command, nil)
  output:flush()

  local header_data_raw = input:read_bytes(HEADER_SIZE, nil)
  if not header_data_raw then 
    print("error no se recibió respuesta del header IPC")
    return nil 
  end
    
  local header_data = header_data_raw:get_data()
  if not header_data or #header_data < HEADER_SIZE then 
    print("Error: Header de respuesta incompleto")
    return nil 
  end
    
  --  string.unpack para lua5.3 >
  local response_header_ptr = ffi.cast("sway_ipc_header_t*", header_data:sub(7))
  local resp_length = response_header_ptr.length

  local response_raw = input:read_bytes(resp_length, nil)
  if not response_raw then
    print("error no se recibió payload de respuesta IPC")
    return nil
  end
    
  local response = response_raw:get_data()
    
  return response
end

function M.close(conn)
  if conn then
    conn:close()
  end
end

function M.get_workspaces(conn)
  local json_string = M.send_raw(conn, "get_workspaces", M.GET_WORKSPACES)
  return json_string
end

function M.get_outputs(conn)
    local json_string = M.send_raw(conn, "get_outputs", M.GET_OUTPUTS)
    return parse_json_to_lua(json_string)
end

function M.get_tree(conn)
    local json_string = M.send_raw(conn, "get_tree", M.GET_TREE)
    return parse_json_to_lua(json_string)
end

function M.get_version(conn)
    local json_string = M.send_raw(conn, "get_version", M.GET_VERSION)
    return json_string
end

function M.run_command(conn, command)
  local json_string = M.send_raw(conn, command, M.COMMAND)
  return json_string
end

function M.exec(conn, app_command)
  return M.run_command(conn, "exec " .. app_command)
end

function M.workspace(conn, name)
  return M.run_command(conn, "workspace " .. name)
end

function M.focus(conn, direction)
  return M.run_command(conn, "focus " .. direction)
end

function M.switch_workspace(conn, workspace_name)
  return M.run_command(conn, "workspace " .. workspace_name)
end -- es lo mismo que workspace para mas largo el nombre de la funcion 

return M
