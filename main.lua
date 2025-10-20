local ffi = require("ffi")
ffi.C = ffi.load("gtk4-layer-shell")

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local LayerShell = lgi.require("Gtk4LayerShell", "1.0")
local GLib = lgi.require("GLib")
local Gio = lgi.Gio
local Adw = lgi.Adw

local Dashboard = require("dashboard")

local appID = "io.github.poloz_z.CandyShell.Lua.Gtk4.Shell"
local appTitle = "Unified Shell"
local app = Adw.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

function app:on_startup()
    local bg_win = Adw.ApplicationWindow.new(self)
    bg_win:set_resizable(false)

    -- Carga el archivo CSS
    local provider = Gtk.CssProvider()
    -- Asumiendo que custom.css está en el mismo path o se ajustará
    provider:load_from_path("custom.css")
    local display = bg_win:get_display()
    Gtk.StyleContext.add_provider_for_display(display, provider, 600)

    -- Capa del shell (fondo)
    LayerShell.init_for_window(bg_win)
    LayerShell.set_layer(bg_win, LayerShell.Layer.BACKGROUND)
    LayerShell.set_exclusive_zone(bg_win, -1)
    LayerShell.set_anchor(bg_win, LayerShell.Edge.LEFT, true)
    LayerShell.set_anchor(bg_win, LayerShell.Edge.RIGHT, true)
    LayerShell.set_anchor(bg_win, LayerShell.Edge.TOP, true)
    LayerShell.set_anchor(bg_win, LayerShell.Edge.BOTTOM, true)
    LayerShell.set_margin(bg_win, LayerShell.Edge.LEFT, 0)
    LayerShell.set_margin(bg_win, LayerShell.Edge.RIGHT, 50)
    LayerShell.set_margin(bg_win, LayerShell.Edge.TOP, 0)
    LayerShell.set_margin(bg_win, LayerShell.Edge.BOTTOM, 15)

    -- wallpaper
    local wallpaper = Gtk.Picture.new_for_filename("res/wall.png")
    wallpaper.content_fit = Gtk.ContentFit.COVER
    wallpaper.halign = Gtk.Align.FILL
    wallpaper.valign = Gtk.Align.FILL
    wallpaper.hexpand = true
    wallpaper.vexpand = true
    wallpaper:add_css_class("wallpaper")

    local top_bar_widget = Dashboard.create_dashboard(Gtk, LayerShell, GLib)

    -- INICIO DEL CAMBIO: Reemplazamos Gtk.Label por Gtk.Box para espaciadores limpios
    -- Espaciador lateral izquierdo (10px de ancho)
    local left_bar = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
    left_bar:set_size_request(10, 1) -- Se mantiene el tamaño de 10px de ancho

    -- Espaciador lateral derecho (50px de ancho)
    local right_bar = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
    right_bar:set_size_request(50, 1) -- Se mantiene el tamaño de 50px de ancho

    -- Espaciador inferior (10px de alto)
    local bottom_bar = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
    bottom_bar:set_size_request(1, 10) -- Se mantiene el tamaño de 10px de alto
    -- FIN DEL CAMBIO

    -- desktop grids
    local celdas = Gtk.Grid.new()
    celdas:attach(top_bar_widget, 0, 0, 3, 1)
    celdas:attach(left_bar,       0, 1, 1, 1)
    celdas:attach(wallpaper,      1, 1, 1, 1)
    celdas:attach(right_bar,      2, 1, 1, 1)
    celdas:attach(bottom_bar,     0, 2, 3, 1)

    bg_win.content = celdas
    bg_win:present()

    ----------------------------------------------------------------
    -----------------------------BARRA------------------------------
    ----------------------------------------------------------------
    local bar_win = Gtk.ApplicationWindow.new(self)
    bar_win:set_default_size(1,1)

    -- Capa del shell (barra)
    LayerShell.init_for_window(bar_win)
    LayerShell.set_layer(bar_win, LayerShell.Layer.TOP)
    LayerShell.set_anchor(bar_win, LayerShell.Edge.LEFT, false)
    LayerShell.set_anchor(bar_win, LayerShell.Edge.RIGHT, true)
    LayerShell.set_anchor(bar_win, LayerShell.Edge.TOP, true)
    LayerShell.set_anchor(bar_win, LayerShell.Edge.BOTTOM, true)
    LayerShell.set_margin(bar_win, LayerShell.Edge.LEFT, 40)
    LayerShell.set_margin(bar_win, LayerShell.Edge.RIGHT, 0)
    LayerShell.set_margin(bar_win, LayerShell.Edge.TOP, 0)
    LayerShell.set_margin(bar_win, LayerShell.Edge.BOTTOM, 0)
    LayerShell.auto_exclusive_zone_enable(bar_win)

    --bar_win.child = Gtk.Label.new("E")
    --bar_win:present()
end

function app:on_activate()
    self.active_window:present()
end

return app:run(arg)