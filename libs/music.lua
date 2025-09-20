local lgi = require("lgi")
local Playerctl = lgi.require("Playerctl")
local GLib = lgi.require("GLib")
local GdkPixbuf = lgi.require("GdkPixbuf")

local M = {}

function M.player_info()
  player = Playerctl.Player.new()
  return {
  	artist = player:print_metadata_prop("xesam:artist"),
  	title  = player:print_metadata_prop("xesam:title"),
  	album  = player:print_metadata_prop("xesam:album"),
  	artUrl = player:print_metadata_prop("mpris:artUrl"),
  	length = player:print_metadata_prop("mpris:length")
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
  to_second = math.floor(info.length/1000000) 
  return to_second
end

function M.get_position()
  player = Playerctl.Player.new()
  position = player:get_position()
  to_second = math.floor(position/1000000) 
  return to_second
end

function M.length_min_sec()
  local seconds = M.length()
  local min = math.floor(seconds / 60)
  local sec = seconds % 60
  bstr = min..":"..sec
  return bstr
end

function M.play_pause()
  player = Playerctl.Player.new()
  return player:play_pause()
end

function M.next()
  player = Playerctl.Player.new()
  return player:next()
end

function M.previous()
  player = Playerctl.Player.new()
  return player:previous()
end

function M.get_album_art()
  -- para los usarios de awesomewm es necesario cargar la superficie cairo desde pixbuf
  local info = M.player_info()
  local artUrlstr = info.artUrl

  if artUrlstr and string.find(artUrlstr, "^data:image/.*;base64,") then
    image64 = string.gsub(artUrlstr, "^data:image/[^;]*;base64,", "")
    decode_image = GLib.base64_decode(image64)
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
      
end

return M