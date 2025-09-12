local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local GLib = lgi.require("GLib", "2.0")
local GdkPixbuf = lgi.require("GdkPixbuf", "2.0")
local Playerctl = lgi.require("Playerctl")
local Gio = lgi.Gio

local appID = "io.github.poloz_z.GTK-test.Lua.Gtk4.Image"
local app_tile = "GtkImageBS64"
local app = Gtk.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

function app:on_startup()
  local window = Gtk.ApplicationWindow.new(self)
  local box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)

  window.child = box
  window.title = app_tile
  window:set_default_size(400, 400)

  c = Playerctl.Player.new()

  image64str = c:print_metadata_prop("mpris:artUrl")
  image64 = string.gsub(image64str, "^data:image/jpeg;base64,", "")
  decode_image = GLib.base64_decode(image64)

  imagePix = GdkPixbuf.PixbufLoader.new()
  imagePix:write(decode_image)
  imagePix:close()

  pixbuf = imagePix:get_pixbuf()

  image = Gtk.Picture.new_for_pixbuf(pixbuf)

  box.valign = Gtk.Align.CENTER
  box:append(Gtk.Label.new("Label 1"))
  box:append(image)
end

function app:on_activate()
  self.active_window:present()
end

return app:run(arg)
