local ffi = require("ffi")
ffi.C = ffi.load("gtk4-layer-shell")

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local LayerShell = lgi.require("Gtk4LayerShell", "1.0")
local GLib = lgi.require("GLib")
local Gio = lgi.Gio

local Dashboard = require("dashboard")

local appID = "io.github.poloz_z.CandyShell.Lua.Gtk4.Shell"
local appTitle = "GtkImage"
local app = Gtk.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

function app:on_startup()
  local win = Gtk.ApplicationWindow.new(self)
  win:set_resizable(False)

  -- Carga el archivo CSS
  local provider = Gtk.CssProvider()
  provider:load_from_path("custom.css")
  local display = win:get_display()
  Gtk.StyleContext.add_provider_for_display(display, provider, 600)

  -- capa del shell
  LayerShell.init_for_window(win)
  LayerShell.set_layer(win, LayerShell.Layer.BACKGROUND)
  LayerShell.set_exclusive_zone(win, -1)
  LayerShell.set_anchor(win, LayerShell.Edge.LEFT, true)
  LayerShell.set_anchor(win, LayerShell.Edge.RIGHT, true)
  LayerShell.set_anchor(win, LayerShell.Edge.TOP, true)
  LayerShell.set_anchor(win, LayerShell.Edge.BOTTOM, true)
  LayerShell.set_margin(win, LayerShell.Edge.LEFT, 0)
  LayerShell.set_margin(win, LayerShell.Edge.RIGHT, 50)
  LayerShell.set_margin(win, LayerShell.Edge.TOP, 0)
  LayerShell.set_margin(win, LayerShell.Edge.BOTTOM, 15)

  -- wallpaper
  local wallpaper = Gtk.Picture.new_for_filename("wall.jpg")
  wallpaper.content_fit = Gtk.ContentFit.COVER
  wallpaper.halign = Gtk.Align.FILL
  wallpaper.valign = Gtk.Align.FILL
  wallpaper.hexpand = true
  wallpaper.vexpand = true
  wallpaper:add_css_class("wallpaper")

  -- dashboard
  local top_bar = Dashboard.create_dashboard(Gtk, LayerShell, GLib)

  local left_bar = Gtk.Label.new("l")
  left_bar:set_size_request(10, 1)

  local right_bar = Gtk.Label.new()
  right_bar:set_size_request(50, 1)

  local bottom_bar = Gtk.Label.new()
  bottom_bar:set_size_request(1, 10)

  -- desktop grids
  local celdas = Gtk.Grid.new()
  celdas:attach(top_bar, 0, 0, 3, 1)
  celdas:attach(left_bar, 0, 1, 1, 1)
  celdas:attach(wallpaper, 1, 1, 1, 1)
  celdas:attach(right_bar, 2, 1, 1, 1)
  celdas:attach(bottom_bar, 0, 2, 3, 1)

  win.child = celdas
end

function app:on_activate()
  self.active_window:present()
end

return app:run(arg)