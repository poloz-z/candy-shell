local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local GLib = lgi.require("GLib", "2.0")
local GdkPixbuf = lgi.require("GdkPixbuf", "2.0")
local Playerctl = lgi.require("Playerctl")
local Gio = lgi.Gio

local appID = "io.github.poloz_z.GTK-test.Lua.Gtk4.Image"
local app_tile = "GtkImageBS64"
local app = Gtk.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

local function update_metadata(image, title_label, artist_label)
    local c = Playerctl.Player.new()
    
    -- Obtener metadatos
    local image64str = c:print_metadata_prop("mpris:artUrl")
    local title = c:print_metadata_prop("xesam:title")
    local artist = c:print_metadata_prop("xesam:artist")
    
    -- Actualizar labels
    title_label:set_text(title or "sin titulo")
    artist_label:set_text(artist or "sin artista")
    
    if image64str then
        if string.find(image64str, "^data:image/.*;base64,") then
            local image64 = string.gsub(image64str, "^data:image/[^;]*;base64,", "")
            local decode_image = GLib.base64_decode(image64)
            if decode_image then
                local loader = GdkPixbuf.PixbufLoader.new()
                loader:write(decode_image)
                loader:close()
                image:set_pixbuf(loader:get_pixbuf())
            end
        elseif string.find(image64str, "^file://") then
            local file_path = string.gsub(image64str, "^file://", "")
            file_path = GLib.uri_unescape_string(file_path, nil)
            local pixbuf = GdkPixbuf.Pixbuf.new_from_file(file_path)
            image:set_pixbuf(pixbuf)
        end
    end
    
    return true
end

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

    box:append(title_label)
    box:append(artist_label)
    box:append(image)
    box.valign = Gtk.Align.CENTER

    -- Actualizar cada segundo
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, function()
        return update_metadata(image, title_label, artist_label)
    end)
end

function app:on_activate()
    self.active_window:present()
end

return app:run(arg)