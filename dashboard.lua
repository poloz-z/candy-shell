local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local GdkPixbuf = lgi.require("GdkPixbuf", "2.0")
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
  search.start_widget = Gtk.Image.new_from_file("res/google.svg")
  search.center_widget = Gtk.Label.new()
  search.end_widget = Gtk.Image.new_from_file("res/search.svg")
  start_dashboard:append(search)

  start_dashboard_main:append(start_dashboard)
  

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


  
  --------- CENTER BOX
  local center_box_dashboard = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  center_box_dashboard.margin_bottom = 10
  center_box_dashboard.margin_start = 20
  center_box_dashboard.margin_top = 10
  center_box_dashboard:add_css_class("box_icon")
  center_box_dashboard:set_size_request(300, 0)

  local icon_buf = GdkPixbuf.Pixbuf.new_from_file_at_scale('res/icon.jpg',100, 100, true)
  local imgbuf = Gdk.Texture.new_for_pixbuf(icon_buf)
  local icon_pfp = Gtk.Picture.new_for_paintable(imgbuf)
  icon_pfp.margin_start = 10
  icon_pfp.margin_top = 10
  icon_pfp:add_css_class('profile_icon')


  local name_label = Gtk.Label.new('Yyrrka Polo 🌸')
  name_label.margin_start = 10
  name_label.margin_top = 10
  name_label:add_css_class('name_label')

  local frase = Gtk.Label.new('Mais distante da luz.\nMais próxima do vazio.')
  frase:add_css_class('frase_label')

  local tray_power = Gtk.CenterBox.new()
  tray_power.margin_start = 30
  tray_power.margin_top = 35

  local poweroff_icon = Gtk.Image.new_from_file('res/power.svg')
  local poweroff_button = Gtk.Button.new()
  poweroff_button:set_size_request(32, 32)
  poweroff_button:set_child(poweroff_icon)
  poweroff_button:add_css_class("tray_button")
  function poweroff_button:on_clicked()
    GLib.spawn_command_line_sync("systemctl poweroff")
  end

  local exit_icon = Gtk.Image.new_from_file('res/exit.svg')
  local exit_button = Gtk.Button.new()
  exit_button:set_size_request(32, 32)
  exit_button:set_child(exit_icon)
  exit_button:add_css_class("tray_button")
  function exit_button:on_clicked()
    GLib.spawn_command_line_sync("swaymsg exit")
  end


  local lock_icon = Gtk.Image.new_from_file('res/lock.svg')
  local lock_button = Gtk.Button.new()
  lock_button:set_size_request(32, 32)
  lock_button:set_child(lock_icon)
  lock_button:add_css_class("tray_button")

  tray_power.start_widget = poweroff_button
  tray_power.center_widget = exit_button
  tray_power.end_widget = lock_button

  local celdas = Gtk.Grid.new()
  celdas:attach(icon_pfp, 1, 1, 1, 1)  -- columna, fila, ancho, alto
  celdas:attach(name_label, 2, 1, 1, 1)
  celdas:attach(frase, 1, 2, 3, 1)
  celdas:attach(tray_power,  1, 3, 3, 1)

  center_box_dashboard:append(celdas)

  local dashboard = Gtk.CenterBox.new()
  dashboard:set_size_request(0, 300)
  dashboard.hexpand = false
  dashboard.vexpand = false
  dashboard.start_widget = start_dashboard_main
  dashboard.center_widget = center_box_dashboard
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