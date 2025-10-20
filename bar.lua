local ffi = require("ffi")
ffi.C = ffi.load("gtk4-layer-shell")

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local LayerShell = lgi.require("Gtk4LayerShell", "1.0")
local GLib = lgi.require("GLib")
local Gio = lgi.Gio

local Dashboard = require("dashboard")

local appID = "io.github.poloz_z.CandyShell.Lua.Gtk4.Shell"
local appTitle = "Bar"
local app = Gtk.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

function app:on_startup()
  local win = Gtk.ApplicationWindow.new(self)
  win:set_resizable(False)

  -- capa del shell
  LayerShell.init_for_window(win)
  LayerShell.set_layer(win, LayerShell.Layer.TOP)
  --LayerShell.set_exclusive_zone(win, -1)
  LayerShell.set_anchor(win, LayerShell.Edge.LEFT, false)
  LayerShell.set_anchor(win, LayerShell.Edge.RIGHT, true)
  LayerShell.set_anchor(win, LayerShell.Edge.TOP, true)
  LayerShell.set_anchor(win, LayerShell.Edge.BOTTOM, true)
  LayerShell.set_margin(win, LayerShell.Edge.LEFT, 10)
  LayerShell.set_margin(win, LayerShell.Edge.RIGHT, 0)
  LayerShell.set_margin(win, LayerShell.Edge.TOP, 0)
  LayerShell.set_margin(win, LayerShell.Edge.BOTTOM, 10)
  LayerShell.auto_exclusive_zone_enable(win)
  --window:set_default_size(700, 60)


  win.child = Gtk.Label.new("E")
end

function app:on_activate()
  self.active_window:present()
end

return app:run(arg)