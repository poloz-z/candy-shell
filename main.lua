-- main.lua
local ffi = require("ffi")
ffi.C = ffi.load("gtk4-layer-shell")

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local LayerShell = lgi.require("Gtk4LayerShell", "1.0")
local GLib = lgi.require("GLib")
local Gio = lgi.Gio
local Adw = lgi.require("Adw")

local SystemInfo = require('libs.system_i')
local NetworkManager = require('libs.nm')
local GApps = require('libs.gapps')
local Theme = require('libs.theme')

local Dashboard = require("dashboard")

local appID = "io.github.poloz_z.CandyShell.Lua.Gtk4.Shell"
local appTitle = "Unified Shell"
local app = Adw.Application.new(appID, Gio.ApplicationFlags.FLAGS_NONE)

GLib.timeout_add_seconds(GLib.PRIORITY_LOW, 30, function()
  collectgarbage("collect")
  return true
end)

local function create_battery_label()
  local battery_label = Gtk.Label.new("")
  battery_label:set_use_markup(true)
  battery_label:add_css_class("sys-status-text")

  local fa_icons = {
    charging = "󰂄", full = "󰁹", battery_90 = "󰂂", battery_80 = "󰂁",
    battery_70 = "󰂀", battery_60 = "󰁿", battery_50 = "󰁾", battery_40 = "󰁽",
    battery_30 = "󰁼", battery_20 = "󰁻", battery_10 = "󰁺", battery_0 = "󰂎"
  }

  local function update_battery()
    local percentage = SystemInfo.get_battery_percentage() or 0
    local state = SystemInfo.get_battery_state() or 0
    local is_charging = (state == 1)
    local icon = ""

    if is_charging then
      icon = fa_icons.charging
    elseif percentage >= 95 then icon = fa_icons.full
    elseif percentage >= 85 then icon = fa_icons.battery_90
    elseif percentage >= 75 then icon = fa_icons.battery_80
    elseif percentage >= 65 then icon = fa_icons.battery_70
    elseif percentage >= 55 then icon = fa_icons.battery_60
    elseif percentage >= 45 then icon = fa_icons.battery_50
    elseif percentage >= 35 then icon = fa_icons.battery_40
    elseif percentage >= 25 then icon = fa_icons.battery_30
    elseif percentage >= 15 then icon = fa_icons.battery_20
    elseif percentage >= 5 then icon = fa_icons.battery_10
    else 
      icon = fa_icons.battery_0
    end

    battery_label:set_markup(string.format(
      '<span>%s %d%%</span>',
      icon, math.floor(percentage)
    ))
    return true
  end

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 30, update_battery)
  update_battery()
  return battery_label
end

-- Widget WiFi
local function create_wifi_label()
  local wifi_label = Gtk.Label.new("")
  wifi_label:set_use_markup(true)
  wifi_label:add_css_class("sys-status-text")

  local wifi_icons = {
    excellent = "󰤨", good = "󰤥", fair = "󰢾", weak = "󰤟", none = "󰤮"
  }

  local function update_wifi()
    local strength = NetworkManager.get_wifi_strength() or 0
    local connected = NetworkManager.is_wifi_connected()
    local icon = wifi_icons.none

    if connected then
      if strength >= 75 then icon = wifi_icons.excellent
      elseif strength >= 50 then icon = wifi_icons.good
      elseif strength >= 25 then icon = wifi_icons.fair
      else icon = wifi_icons.weak end
    end

    wifi_label:set_markup(string.format('<span>%s</span>', icon))
    return true
  end

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 15, update_wifi)
  update_wifi()
  return wifi_label
end

local function create_time_label()
  local time_label = Gtk.Label.new(os.date("%H:%M"))
  time_label:add_css_class("sys-status-text")

  local function update_time()
    time_label:set_text(os.date("%H:%M"))
    return true
  end

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, update_time)
  return time_label
end

local function create_system_status_box()
  local box = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 20) 
  box:add_css_class("sys-status-box")
  box.valign = Gtk.Align.CENTER

  box:append(create_wifi_label())    
  box:append(create_battery_label()) 
  box:append(create_time_label())

  return box
end

local function create_app_button(app_id)
  local all_apps = GApps.get_all_apps()
  local app_data = all_apps[app_id]

  if not app_data then return nil end

  local button = Gtk.Button.new()
  button:add_css_class("apps-box")

  local image = Gtk.Image.new_from_gicon(app_data.icon)
  image:set_pixel_size(32) 
  
  button:set_child(image)
  button:set_tooltip_text(app_data.name)

  button.on_clicked = function()
    app_data.launch()
  end

  return button
end

local pinned_apps = { 
  "org.telegram.desktop._7b8e57b5241cb68ef979736501a5169d.desktop", 
  "thunar.desktop", 
  "vlc.desktop", 
  "firefox.desktop", 
  "sublime_text.desktop", 
  "kitty.desktop" 
}

function app:on_startup()
  local bg_win = Adw.ApplicationWindow.new(self)
  bg_win:set_resizable(false)

  --wallpaper_path = "res/bocci.png"

  local provider = Gtk.CssProvider()
  provider:load_from_path("custom.css")
  local display = bg_win:get_display()
  Gtk.StyleContext.add_provider_for_display(display, provider, 600)

  LayerShell.init_for_window(bg_win)
  LayerShell.set_layer(bg_win, LayerShell.Layer.BACKGROUND)
  LayerShell.set_exclusive_zone(bg_win, -1)
  LayerShell.set_anchor(bg_win, LayerShell.Edge.LEFT, true)
  LayerShell.set_anchor(bg_win, LayerShell.Edge.RIGHT, true)
  LayerShell.set_anchor(bg_win, LayerShell.Edge.TOP, true)
  LayerShell.set_anchor(bg_win, LayerShell.Edge.BOTTOM, true)
  LayerShell.set_margin(bg_win, LayerShell.Edge.LEFT, 0)
  LayerShell.set_margin(bg_win, LayerShell.Edge.RIGHT, 0)
  LayerShell.set_margin(bg_win, LayerShell.Edge.TOP, 0)
  LayerShell.set_margin(bg_win, LayerShell.Edge.BOTTOM, 0)


  local last_wallpaper, last_mode = Theme.get_saved_settings()

  local current_mode = last_mode
  local current_wp_path = last_wallpaper

  Theme.apply(current_wp_path, current_mode)

  -- nuevo metodo para wallpaper darle click izquierdo para elegir nuevo fondo
  -- y click derecho para intercambiar entre tema (ligth o dark)
  local wallpaper = Gtk.Picture.new_for_filename(current_wp_path)
  wallpaper.content_fit = Gtk.ContentFit.COVER
  wallpaper.halign = Gtk.Align.FILL
  wallpaper.valign = Gtk.Align.FILL
  wallpaper.hexpand = true
  wallpaper.vexpand = true
  wallpaper:add_css_class("wallpaper")

  local wp_file_dialog = Gtk.FileDialog.new()
  wp_file_dialog.title = "new wallpaper"
  
  local wp_filter = Gtk.FileFilter.new()
  wp_filter:set_name("Imágenes")
  wp_filter:add_mime_type("image/jpeg")
  wp_filter:add_mime_type("image/png")
  wp_filter:add_mime_type("image/webp")
  
  local wp_filters_store = Gio.ListStore.new(Gtk.FileFilter)
  wp_filters_store:append(wp_filter)
  wp_file_dialog:set_filters(wp_filters_store)

  local click_controller = Gtk.GestureClick.new()
  click_controller:set_button(0) 
  
  function click_controller:on_pressed(n_press, x, y)
    local btn = self:get_current_button()

    if btn == 1 then
      wp_file_dialog:open(nil, nil, function(dialog, result)
        local file, err = dialog:open_finish(result)
        if file then
          current_wp_path = file:get_path()
          wallpaper:set_file(file)
          pcall(function() 
            Theme.apply(current_wp_path, current_mode) 
            Theme.save_settings(current_wp_path, current_mode)
          end)
        end
      end)

    elseif btn == 3 then
      if current_mode == "light" then
        current_mode = "dark"
      else
        current_mode = "light"
      end
      pcall(function() 
        Theme.apply(current_wp_path, current_mode) 
        Theme.save_settings(current_wp_path, current_mode)
      end)
    end
  end

  wallpaper:add_controller(click_controller)

  local top_bar_widget = Dashboard.create_dashboard(Gtk, LayerShell, GLib)

  local left_bar = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  left_bar:set_size_request(15, 1) 

  local right_bar = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  right_bar:set_size_request(15, 1)

  local bottom_bar = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  bottom_bar:set_size_request(1, 65) 

  local celdas = Gtk.Grid.new()
  celdas:attach(top_bar_widget, 0, 0, 3, 1)
  celdas:attach(left_bar,       0, 1, 1, 1)
  celdas:attach(wallpaper,      1, 1, 1, 1)
  celdas:attach(right_bar,      2, 1, 1, 1)
  celdas:attach(bottom_bar,     0, 2, 3, 1)

  bg_win.content = celdas
  bg_win:present()

  local bar_win = Gtk.ApplicationWindow.new(self)
  bar_win:set_default_size(1, 50)
  bar_win:add_css_class("barra-shell")

  LayerShell.init_for_window(bar_win)
  LayerShell.set_layer(bar_win, LayerShell.Layer.TOP)
  LayerShell.set_anchor(bar_win, LayerShell.Edge.LEFT, true)
  LayerShell.set_anchor(bar_win, LayerShell.Edge.RIGHT, true)
  LayerShell.set_anchor(bar_win, LayerShell.Edge.TOP, false)
  LayerShell.set_anchor(bar_win, LayerShell.Edge.BOTTOM, true)
  
  LayerShell.set_margin(bar_win, LayerShell.Edge.LEFT, 15)
  LayerShell.set_margin(bar_win, LayerShell.Edge.RIGHT, 15)
  LayerShell.set_margin(bar_win, LayerShell.Edge.TOP, 0)
  LayerShell.set_margin(bar_win, LayerShell.Edge.BOTTOM, 3)
  LayerShell.auto_exclusive_zone_enable(bar_win)

  local main_bar = Gtk.CenterBox.new()
  main_bar.orientation = Gtk.Orientation.HORIZONTAL 
  main_bar.margin_start = 10 
  main_bar.margin_end = 10
  main_bar.margin_top = 0 
  main_bar.margin_bottom = 0
  main_bar:add_css_class('bottom-bar') 

  local launcher_circular = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  launcher_circular:add_css_class("launcher-circular")
  launcher_circular.valign = Gtk.Align.CENTER
  launcher_circular.halign = Gtk.Align.CENTER

  local start_widgets = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 10)
  start_widgets:append(launcher_circular)

  local center_apps_box = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 8)
  center_apps_box:add_css_class("center-pinned-apps")
  center_apps_box.valign = Gtk.Align.CENTER
  center_apps_box.halign = Gtk.Align.CENTER

  for _, id in ipairs(pinned_apps) do
    local btn = create_app_button(id)
    if btn then
      center_apps_box:append(btn)
    end
  end

  main_bar.start_widget = start_widgets
  main_bar.center_widget = center_apps_box
  main_bar.end_widget = create_system_status_box()

  bar_win.child = main_bar
  bar_win:present()
end

function app:on_activate()
  self.active_window:present()
end

return app:run(arg)