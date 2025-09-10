local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local GLib = lgi.require("GLib")

local calendario = require("calendario")

local M = {}
function M.create_dashboard(Gtk, LayerShell, GLib)
  local f = os.date("*t")
    
  -- contenedor principal del dashboard
  local center_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  center_box:set_size_request(-1, 10)


  local start_dashboard_main = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  start_dashboard_main.margin_start = 10
  start_dashboard_main.margin_top = 10




  local start_dashboard = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)



  -- Crear el calendario usando el módulo separado
  local widget_calendario = calendario.updatable_calendar()
  start_dashboard:append(widget_calendario)

  local search = Gtk.CenterBox.new()
  search:add_css_class('box-search')
  search.start_widget = Gtk.Image.new_from_file("google.svg")
  search.center_widget = Gtk.Label.new()
  search.end_widget = Gtk.Image.new_from_file("search.svg")
  start_dashboard:append(search)

  start_dashboard_main:append(start_dashboard)
  
  --imgbuf = Gdk.Paintable.new_empty(200, 100)
  --local pfp = Gtk.Picture.new_for_paintable(imgbuf)
  --pfp.hexpand = false
  --pfp.vexpand = false
  --pfp.halign = Gtk.Align.CENTER
  --pfp.valign = Gtk.Align.CENTER

  local box_pfp = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  box_pfp.margin_start = 30
  box_pfp.margin_bottom = 10
  box_pfp:set_size_request(250, 100)
  box_pfp:add_css_class("pfp")

  local function update_time(label)
    local now = os.date("%H:%M")
    label:set_text(now)
    return true
  end

  local function create_time()
    local time_label = Gtk.Label.new(os.date("%H:%M"))
    time_label.halign = Gtk.Align.END
    time_label:add_css_class("time_label")
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, function()
      return update_time(time_label)
    end)
    
    return time_label
  end
  local time_widget = create_time()
  box_pfp:append(time_widget)


  local user = Gtk.Label.new("@"..os.getenv("USER").." 🤍")
  user.margin_top = 175
  user.halign = Gtk.Align.START  
  user.valign = Gtk.Align.START  
  user:add_css_class("user_label") 
  box_pfp:append(user)


  local function update_uptime(label)
    local f = io.popen("uptime -p")
    if f then
      local uptime_str = f:read("*a")
      f:close()
      local formatted_uptime = uptime_str:gsub("\n", "")
      label:set_text(formatted_uptime)
    end
    return true
  end

  local function create_uptime()
    local uptime_label = Gtk.Label.new()
    uptime_label.halign = Gtk.Align.START
    uptime_label.margin_bottom = 10
    user.valign = Gtk.Align.START 
    uptime_label:add_css_class("user_label")
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, function()
      return update_uptime(uptime_label)
    end)
    update_uptime(uptime_label) 
    return uptime_label
  end
  local uptime = create_uptime()
  box_pfp:append(uptime)


  start_dashboard_main:append(box_pfp)



  

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