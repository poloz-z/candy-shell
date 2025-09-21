-- sway-ipc
-- falta implementar parseo con Json
local lgi = require('lgi')
local Gio = lgi.Gio

local M = {}

M.COMMAND = 0
M.GET_WORKSPACES = 1
M.GET_OUTPUTS = 3
M.GET_TREE = 4
M.GET_VERSION = 7

function M.connect()
    local path = os.getenv("SWAYSOCK")
    if not path then return nil end
    
    local client = Gio.SocketClient.new()
    local addr = Gio.UnixSocketAddress.new(path)
    return client:connect(addr, nil)
end

function M.send_raw(conn, command, msg_type)
    msg_type = msg_type or M.COMMAND
    
    local output = conn:get_output_stream()
    local input = conn:get_input_stream()
    
    local header = "i3-ipc" .. string.pack("<I4I4", #command, msg_type)
    output:write(header .. command, nil)
    output:flush()
    
    local header_data = input:read_bytes(14, nil):get_data()
    if not header_data or #header_data < 14 then return nil end
    
    local resp_length = string.unpack("<I4", header_data:sub(7, 10))
    local response = input:read_bytes(resp_length, nil):get_data()
    
    return response
end

function M.close(conn)
    if conn then
        conn:close()
    end
end

function M.get_workspaces(conn)
    return M.send_raw(conn, "get_workspaces", M.GET_WORKSPACES)
end

function M.get_outputs(conn)
    return M.send_raw(conn, "get_outputs", M.GET_OUTPUTS)
end

function M.get_tree(conn)
    return M.send_raw(conn, "get_tree", M.GET_TREE)
end

function M.get_version(conn)
    return M.send_raw(conn, "get_version", M.GET_VERSION)
end

function M.run_command(conn, command)
    return M.send_raw(conn, command, M.COMMAND)
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

return M
