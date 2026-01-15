-- libs/theme.lua
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local Json = lgi.require("Json")

local M = {}

local css_provider = Gtk.CssProvider.new()
local display = Gdk.Display.get_default()
if display then
  Gtk.StyleContext.add_provider_for_display(display, css_provider, 800)
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
    print("error parser:", err)
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
    --print(name .. "  " .. value)
    table.insert(css_lines, string.format("@define-color %s %s;", name, value))
  end

  local final_css = table.concat(css_lines, "\n")
  css_provider:load_from_data(final_css, #final_css)
  
  --print("tema aplicado con glibjson (" .. mode .. ")")
end

return M