local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local GLib = lgi.require("GLib", "2.0")
local GdkPixbuf = lgi.require("GdkPixbuf", "2.0")
local Playerctl = lgi.require("Playerctl")
local Gio = lgi.Gio
local music = require("music")

local appID = "io.github.poloz_z.GTK-test.Lua.Gtk4.Image"
local app_tile = "GtkImageBS64"
local app = Gtk.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

function app:on_startup()
    local window = Gtk.ApplicationWindow.new(self)
    local box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)

    window.child = box
    window.title = app_tile
    window:set_default_size(400, 400)

    -- Crear elementos UI
    local title_label = Gtk.Label.new("Cargando...")
    local artist_label = Gtk.Label.new("Cargando...")
    local image = Gtk.Picture.new()
    image:set_pixbuf(music.get_album_art())

    box:append(title_label)
    box:append(artist_label)
    box:append(image)
    box.valign = Gtk.Align.CENTER

end

function app:on_activate()
    self.active_window:present()
end

return app:run(arg)