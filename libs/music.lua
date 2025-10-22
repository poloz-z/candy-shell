local lgi = require("lgi")
local Playerctl = lgi.require("Playerctl")
local GLib = lgi.require("GLib")
local GdkPixbuf = lgi.require("GdkPixbuf")

local M = {}

local player = nil

local function init_player()
  if player then return player end
   
  local new_player = Playerctl.Player.new()
  
  if new_player then
    player = new_player
    player.on_exit = function(self)
      player = nil
    end
  end
  return player
end


local function get_player()
  if not player then
    return init_player()
  end
  return player
end

function M.player_info()
  local current_player = get_player()
  if not current_player then
    return {
      artist = "none",
      title  = "none",
      album  = "none",
      artUrl = "none",
      length = 0
    }
  end

  return {
    artist = current_player:print_metadata_prop("xesam:artist"),
    title  = current_player:print_metadata_prop("xesam:title"),
    album  = current_player:print_metadata_prop("xesam:album"),
    artUrl = current_player:print_metadata_prop("mpris:artUrl"),
    length = current_player:print_metadata_prop("mpris:length")
  }
end

function M.get_artist()
    local info = M.player_info()
    return info.artist
end

function M.get_title()
  local info = M.player_info()
  return info.title
end

function M.get_album()
  local info = M.player_info()
  return info.album
end

function M.length()
  local info = M.player_info()
  if info.length then
    local to_second = math.floor(info.length/1000000) 
    return to_second
  end
  return 0
end

function M.get_position()
  local current_player = get_player()
  if not current_player then
    return 0
  end
  local position = current_player:get_position()
  if position then
    local to_second = math.floor(position/1000000) 
    return to_second
  end
  return 0
end


function M.length_min_sec()
  local seconds = M.length()
  local min = math.floor(seconds / 60)
  local sec = seconds % 60
  local bstr = min..":"..(sec < 10 and "0"..sec or sec)
  return bstr
end

function M.play_pause()
  local current_player = get_player()
  return current_player:play_pause()
end

function M.next()
  local current_player = get_player()
  return current_player:next()
end

function M.previous()
  local current_player = get_player()
  return current_player:previous()
end

function M.get_album_art()
  local info = M.player_info()
  local artUrlstr = info.artUrl

  if artUrlstr and string.find(artUrlstr, "^data:image/.*;base64,") then
    local image64 = string.gsub(artUrlstr, "^data:image/[^;]*;base64,", "")
    local decode_image = GLib.base64_decode(image64)
    if decode_image then
      local imagePix = GdkPixbuf.PixbufLoader.new()
      imagePix:write(decode_image)
      imagePix:close()
      return imagePix:get_pixbuf()
    end
  end

  if artUrlstr and string.find(artUrlstr, "^file://") then
    local file_path = string.gsub(artUrlstr, "^file://", "")
    file_path = GLib.uri_unescape_string(file_path, nil)
    return GdkPixbuf.Pixbuf.new_from_file(file_path)
  end
  return nil
end

function M.reconnect_player()
  player = nil
  return get_player()
end

return M