-- libs/theme.lua
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local Json = lgi.require("Json")
local GLib = lgi.require("GLib")

local M = {}

local config_dir = GLib.get_user_config_dir() .. "/candy-shell"
local config_path = config_dir .. "/config.json"

local css_provider = Gtk.CssProvider.new()
local display = Gdk.Display.get_default()
if display then
  Gtk.StyleContext.add_provider_for_display(display, css_provider, 800)
end

function M.save_settings(image_path, mode)
  GLib.mkdir_with_parents(config_dir, 511)

  local f = io.open(config_path, "w")
  if f then
    local content = string.format('{\n  "wallpaper": "%s",\n  "theme_mode": "%s"\n}', image_path, mode)
    f:write(content)
    f:close()
  end
end

function M.get_saved_settings()
  local f = io.open(config_path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local parser = Json.Parser.new()
    local ok, _ = parser:load_from_data(content, -1)
    if ok then
      local obj = parser:get_root():get_object()
      return obj:get_string_member("wallpaper"), obj:get_string_member("theme_mode")
    end
  end
  return "res/wall.png", "dark"
end

function M.apply(image_path, selected_mode)
  local cmd = string.format("matugen image '%s' -j hex", image_path)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  if not result or result == "" then return end

  local parser = Json.Parser.new()
  local success, err = parser:load_from_data(result, -1)

  if not success then
    print("--error--:", err)
    return
  end

  local root = parser:get_root():get_object()
  local colors_obj = root:get_object_member("colors")

  local mode = selected_mode
  if mode ~= "dark" and mode ~= "light" then
    mode = "dark"
  end

  local palette = colors_obj:get_object_member(mode)
  if not palette then return end

  local css_lines = {}
  local members = palette:get_members()
  for _, name in ipairs(members) do
    local value = palette:get_string_member(name)
    table.insert(css_lines, string.format("@define-color %s %s;", name, value))
  end

  local final_css = table.concat(css_lines, "\n")
  css_provider:load_from_data(final_css, #final_css)
end

return M