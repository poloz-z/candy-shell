local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")

local calendario = require("calendario")

local M = {}
function M.create_dashboard(Gtk, LayerShell)
  local f = os.date("*t")
    
  -- contenedor principal del dashboard
  local center_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  center_box:set_size_request(-1, 10)


  local start_dashboard_main = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 10)
  start_dashboard_main.margin_start = 10
  start_dashboard_main.margin_top = 10


  imgbuf = Gdk.Paintable.new_empty(200, 100)
  local pfp = Gtk.Picture.new_for_paintable(imgbuf)
  pfp.hexpand = false
  pfp.vexpand = false
  pfp.halign = Gtk.Align.CENTER
  pfp.valign = Gtk.Align.CENTER
  pfp:add_css_class("pfp")

  local start_dashboard = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)

  -- Crear el calendario usando el módulo separado
  local widget_calendario = calendario.crear_calendario(f.month, f.year)
  start_dashboard:append(widget_calendario)

  local search = Gtk.CenterBox.new()
  search:add_css_class('box-search')
  search.start_widget = Gtk.Image.new_from_file("google.svg")
  search.center_widget = Gtk.Label.new()
  search.end_widget = Gtk.Image.new_from_file("search.svg")
  start_dashboard:append(search)


  start_dashboard_main:append(start_dashboard)

  local dashboard = Gtk.CenterBox.new()
  dashboard:set_size_request(0, 300)
  dashboard.hexpand = false
  dashboard.vexpand = false
  dashboard.start_widget = start_dashboard_main
  dashboard.center_widget = Gtk.Label.new("dashboard")
  dashboard:add_css_class("dashboard")

  -- revealer para mostrar/ocultar el dashboard
  local revealer = Gtk.Revealer.new()
  revealer.child = dashboard
  revealer.reveal_child = false
  revealer.transition_duration = 500

  -- controlador de eventos para mostrar/ocultar con el mouse
  local motion_controller = Gtk.EventControllerMotion.new()
  function motion_controller:on_enter()
    revealer.reveal_child = true
  end
  function motion_controller:on_leave()
    revealer.reveal_child = false
  end

  center_box:append(revealer)

  local top_bar = Gtk.Overlay.new()
  top_bar:add_css_class("top_panel")
  top_bar:set_child(center_box)
  top_bar:add_controller(motion_controller)

  return top_bar
end

return M