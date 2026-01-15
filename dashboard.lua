-- dashboard.lua
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local Gdk = lgi.require("Gdk", "4.0")
local GdkPixbuf = lgi.require("GdkPixbuf", "2.0")
local GLib = lgi.require("GLib")
local cairo = lgi.require("cairo")

local calendario = require("calendario")
local music = require("libs.music")
local sway = require("libs.sway")

local M = {}

local PI = math.pi
local TWO_PI = 2 * PI

local conn = sway.connect()

local icon_texture = nil
local function get_icon_texture()
  if not icon_texture then
    local icon_buf = GdkPixbuf.Pixbuf.new_from_file_at_scale('res/icon.jpg', 100, 100)
    icon_texture = Gdk.Texture.new_for_pixbuf(icon_buf)
    icon_buf = nil 
  end
  return icon_texture
end

local function create_weather_widget()
  local w = require("libs.weather")
  
  local weather_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 2)
  weather_box:add_css_class("weather-card") 

  local location_label = Gtk.Label.new("loading...")
  location_label:add_css_class("weather-location") 
  location_label:set_use_markup(true)
  
  local temp_label = Gtk.Label.new("󰖒 --°C")
  temp_label:add_css_class("weather-temp") 
  temp_label:set_use_markup(true)
  
  local details_label = Gtk.Label.new("sincronizando...")
  details_label:add_css_class("weather-details") 
  details_label:set_use_markup(true)

  local function refresh_ui()
    if not w.datos.load then return end

    location_label:set_markup(string.format(
      "<span weight='bold'>%s, %s</span>\n<span size='10pt'>%s</span>", 
      w.datos.state, w.datos.country, 
      w.datos.descrip))
    
    temp_label:set_markup(string.format(
      "<span font_desc='24'>%s </span> <span size='22pt' weight='heavy'>%s</span>", 
      w.datos.emoji, 
      w.datos.temp)) 

    details_label:set_markup(string.format(
      "<span size='10pt'>󱪈  %s,  󱪀  %s</span>", 
      w.datos.wind, 
      w.datos.humi))
  end

  local function update_weather()
    details_label:set_markup("<span size='x-small' alpha='50%%'>Updating...</span>")

    w.update(10, 10.48, -66.90, function(data)
      GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, function()
        refresh_ui()
        return false 
      end)
    end)

    if not w.datos.load then
      details_label:set_markup("<span size='x-small' color='#ff5555'>error de conexión</span>")
    end
  end

  -- Ejecución inicial y ciclo de 30 min
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1, function()
    update_weather()
    return false
  end)

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 60, function()
    update_weather()
    return true
  end)

  weather_box:append(location_label)
  weather_box:append(temp_label)
  weather_box:append(details_label)

  return weather_box
end

local function create_sys_widget()
  local System = require("libs.system_i")
  local Gtk = lgi.Gtk
  local GLib = lgi.GLib

  local main_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  main_box:add_css_class("sys-status-card")
  main_box:set_size_request(-1, 100)

  local function create_row(icon, color_class, alignment)
    local row = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 12)
    row:set_valign(Gtk.Align.CENTER)
    row:set_vexpand(true) 

    local icon_label = Gtk.Label.new(icon)
    icon_label:add_css_class("sys-icon-small")

    local bar = Gtk.LevelBar.new()
    bar:set_orientation(Gtk.Orientation.HORIZONTAL)
    bar:set_min_value(0)
    bar:set_max_value(100)
    bar:set_hexpand(true)
    bar:set_valign(Gtk.Align.CENTER) 

    bar:set_size_request(-1, 2) 
    bar:set_margin_start(10)
    bar:set_margin_end(20)
    
    bar:add_css_class("sys-bar-ultra-slim")
    if color_class then bar:add_css_class(color_class) end

    row:append(icon_label)
    row:append(bar)
    
    return row, bar
  end

  local cpu_row, cpu_bar = create_row("", "bar-cpu")
  local ram_row, ram_bar = create_row("", "bar-ram")
  local disk_row, disk_bar = create_row("󰋊", "bar-disk")

  cpu_row:set_valign(Gtk.Align.START)  
  ram_row:set_valign(Gtk.Align.CENTER)
  disk_row:set_valign(Gtk.Align.END)  

  main_box:append(cpu_row)
  main_box:append(ram_row)
  main_box:append(disk_row)

  local function update_stats()
    local cpu_usage = System.get_cpu_used()
    local mem_info = System.get_mem_info()
    local disk_usage = System.get_disk_usage('/') 

    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, function()
      cpu_bar:set_value(cpu_usage)
      ram_bar:set_value(mem_info.ram.percent_real_used)
      disk_bar:set_value(disk_usage)
      return false
    end)
    return true 
  end

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, update_stats)
  update_stats()

  return main_box
end

local function c_music_box()
  local animation_time = 0.0
  local current_progress = 0.0
  local is_playing_state = false
  local wave_color = {r = 1, g = 1, b = 1} 

  local music_box = Gtk.CenterBox.new()
  music_box:set_name("simple_music_box")
  music_box.valign = Gtk.Align.START
  music_box.halign = Gtk.Align.CENTER
  music_box:set_size_request(450, 110) 
  music_box.margin_end = 10
  music_box.margin_top = 10
  music_box.margin_bottom = 10
  music_box:add_css_class("simple-music-box")

  local music_style_provider = Gtk.CssProvider.new()
  local display = Gdk.Display.get_default()
  if display then
    Gtk.StyleContext.add_provider_for_display(display, music_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
  end

  local album_art = Gtk.Image { pixel_size = 110 }
  album_art:add_css_class("album-card")
  album_art.valign = Gtk.Align.CENTER

  local title_label = Gtk.Label { label = "Título", css_classes = { "title-4" } }
  local artist_label = Gtk.Label { label = "Artista", css_classes = { "title-5" } }
  title_label:set_name("music_title")
  artist_label:set_name("music_artist")
  title_label.ellipsize = 3
  artist_label.ellipsize = 3 
  title_label.halign = Gtk.Align.START 
  artist_label.halign = Gtk.Align.START

  local progress_area = Gtk.DrawingArea.new()
  progress_area:set_size_request(-1, 24) 
  progress_area.hexpand = true 
  progress_area.valign = Gtk.Align.CENTER 

  local function draw_progress_wave(area, cr, width, height)
    local padding = 2 
    local y_center = height / 2
    local bar_width = width -- - (padding * 2)
    local active_length = bar_width * current_progress
    local active_end_x = padding + active_length
    local line_height = 3.0 

    if active_end_x < (width - padding) then
      cr:set_source_rgba(0.5, 0.5, 0.5, 0.25)
      cr:set_line_width(line_height)
      cr:set_line_cap(cairo.LineCap.ROUND)
      cr:move_to(active_end_x, y_center)
      cr:line_to(width - padding, y_center)
      cr:stroke()
    end

    cr:set_source_rgb(wave_color.r, wave_color.g, wave_color.b)
    cr:set_line_width(line_height)
    
    if current_progress > 0 then
      local wave_amplitude = is_playing_state and 3.5 or 0.0
      local wave_frequency = 6.0
      local wave_speed = 6.0
      local num_segments = math.max(math.floor(active_length / 1.5), 2)

      cr:move_to(padding, y_center)
      for i = 1, num_segments do
        local x_pos = padding + (i / num_segments) * active_length
        local x_factor = (x_pos - padding) / bar_width
        local wave_offset = math.sin(x_factor * PI * wave_frequency * 2 + animation_time * wave_speed)
        local y_pos = y_center + (wave_offset * wave_amplitude)
        cr:line_to(x_pos, y_pos)
      end
      cr:stroke()

      local indicator_height = 14.0
      local indicator_width = 4.0  
      
      cr:set_line_width(indicator_width)
      cr:set_line_cap(cairo.LineCap.ROUND) 
      
      cr:move_to(active_end_x, y_center - (indicator_height / 2))
      cr:line_to(active_end_x, y_center + (indicator_height / 2))
      cr:stroke()
    end
  end
  progress_area:set_draw_func(draw_progress_wave, nil, nil)

  local m_text_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 1)
  m_text_box:append(title_label)
  m_text_box:append(artist_label)

  local center_layout = Gtk.Box.new(Gtk.Orientation.VERTICAL, 8) 
  center_layout.valign = Gtk.Align.CENTER
  center_layout.margin_start = 15
  center_layout.margin_end = 15
  center_layout:append(m_text_box)
  center_layout:append(progress_area)

  -- Botones de control
  local prev_button = Gtk.Button.new()
  local prev_label = Gtk.Label.new("") 
  prev_button:set_child(prev_label)
  prev_button:add_css_class("music-control-btn")
  prev_button:set_size_request(32, 32)

  local play_pause_button = Gtk.Button.new()
  local play_pause_label = Gtk.Label.new("")
  play_pause_button:set_child(play_pause_label)
  play_pause_button:add_css_class("music-control-btn")
  play_pause_button:set_size_request(32, 32)

  local next_button = Gtk.Button.new()
  local next_label = Gtk.Label.new("")
  next_button:set_child(next_label)
  next_button:add_css_class("music-control-btn")
  next_button:set_size_request(32, 32)

  prev_button.on_clicked = function() music.previous() end
  play_pause_button.on_clicked = function() music.play_pause() end
  next_button.on_clicked = function() music.next() end

  local m_control_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 8)
  m_control_box.valign = Gtk.Align.CENTER
  m_control_box:append(play_pause_button)
  m_control_box:append(next_button)
  m_control_box:append(prev_button)

  music_box.start_widget = album_art
  music_box.center_widget = center_layout
  music_box.end_widget = m_control_box

  local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return {
      r = tonumber("0x"..hex:sub(1,2)) / 255,
      g = tonumber("0x"..hex:sub(3,4)) / 255,
      b = tonumber("0x"..hex:sub(5,6)) / 255
    }
  end

  local function update_music_box()
    local bg_color, text_color = music.get_album_colors()
    local pixbuf = music.get_album_art()
    local info = music.player_info()
    
    wave_color = hex_to_rgb(text_color)

    if info and info.title and info.title ~= "none" then
      local title = tostring(info.title or "")
      local artist = tostring(info.artist or "Desconocido")

      title_label:set_text(#title > 22 and title:sub(1, 19).."..." or title)
      artist_label:set_text(#artist > 20 and artist:sub(1, 18).."..." or artist)
    
      is_playing_state = (info.status == "PLAYING")
      local pos = music.get_position() or 0
      local len = music.length() or 0
      current_progress = (len > 0) and (pos / len) or 0.0
    else
      title_label:set_text("Sin música")
      artist_label:set_text("Reproduce algo")
      is_playing_state = false
      current_progress = 0.0
    end

    play_pause_label:set_text(is_playing_state and "" or "")

    if pixbuf then 
      album_art:set_from_pixbuf(pixbuf)
    else
      album_art:set_from_file('res/no_music.png')
    end

    local css = string.format([[
      #simple_music_box { 
        background-color: %s; 
        background-image: radial-gradient(circle at center, %s 0%%, shade(%s, 0.6) 100%%); 
        /* box-shadow: 0 1px 4px rgba(0, 0, 0, 0.8), 0 1px 4px rgba(0, 0, 0, 0.9); */
        border-radius: 20px; 
        padding: 15px; 
      }
      #music_artist, #music_title { 
        color: %s; 
      }
      .music-control-btn { 
        color: %s; border: none; 
        background: transparent; 
        font-size: 1.2rem; 
      }
    ]], bg_color, bg_color, bg_color, text_color, text_color)

    music_style_provider:load_from_data(css, #css)

    pixbuf = nil
    
    return true 
  end

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, update_music_box)
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 16, function()
    if is_playing_state then
      animation_time = animation_time + 0.016
      progress_area:queue_draw()
    end
    return true
  end)
  
  return music_box
end

function M.create_dashboard(Gtk, LayerShell, GLib)

  local center_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  center_box:set_size_request(-1, 10)

  local start_dashboard_main = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  start_dashboard_main.margin_start = 10
  start_dashboard_main.margin_top = 10

  local start_dashboard = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)

  local widget_calendario = calendario.updatable_calendar()
  start_dashboard:append(widget_calendario)

  local search = Gtk.CenterBox.new()
  search.margin_bottom = 10
  search:add_css_class('box-search')

  local google_icon = Gtk.Label.new("")
  google_icon:add_css_class('icon-font-brands')
  search.start_widget = google_icon

  search.center_widget = Gtk.Label.new()

  local search_icon = Gtk.Label.new("") 
  search_icon:add_css_class('icon-font-solid')
  search.end_widget = search_icon

  start_dashboard:append(search)
  start_dashboard_main:append(start_dashboard)

  local box_pfp = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  box_pfp.margin_start = 30
  box_pfp.margin_bottom = 10
  box_pfp:set_size_request(250, 100)
  box_pfp:add_css_class("pfp")

  local function create_time_widget()
    local time_label = Gtk.Label.new(os.date("%H:%M"))
    time_label.halign = Gtk.Align.END
    time_label:add_css_class("time_label")
    
    local function update_time()
      time_label:set_text(os.date("%H:%M"))
      return true
    end
    
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 60, update_time)
    return time_label
  end
  
  local time_widget = create_time_widget()
  box_pfp:append(time_widget)

  local user = Gtk.Label.new("@" .. os.getenv("USER") )
  user.margin_top = 175
  user.halign = Gtk.Align.START  
  user.valign = Gtk.Align.START  
  user:add_css_class("user_label") 
  box_pfp:append(user)

  local function create_uptime_widget()
    local uptime_label = Gtk.Label.new()
    uptime_label.halign = Gtk.Align.START
    uptime_label.margin_bottom = 10
    uptime_label:add_css_class("user_label")
    
    local function update_uptime()
      local f = io.popen("uptime -p")
      if f then
        local uptime_str = f:read("*a")
        f:close()
        uptime_label:set_text(uptime_str:gsub("\n", ""))
      end
      return true
    end
    
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 30, update_uptime)
    update_uptime()
    return uptime_label
  end
  
  local uptime_widget = create_uptime_widget()
  box_pfp:append(uptime_widget)

  start_dashboard_main:append(box_pfp)

  local center_box_dashboard = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
  center_box_dashboard.margin_bottom = 10
  center_box_dashboard.margin_start = 20
  center_box_dashboard.margin_top = 10
  center_box_dashboard:add_css_class("box_icon")
  center_box_dashboard:set_size_request(300, 0)

  local icon_pfp = Gtk.Picture.new_for_paintable(get_icon_texture())
  icon_pfp.margin_start = 10
  icon_pfp.margin_top = 10
  icon_pfp:add_css_class('profile_icon')

  local name_label = Gtk.Label.new('~Jorge Polo ')
  name_label.margin_start = 10
  name_label.margin_top = 10
  name_label:add_css_class('name_label')

  --local frase = Gtk.Label.new('Mais distante da luz.\nMais próxima do vazio.')
  --frase:add_css_class('frase_label')

  local tray_power = Gtk.CenterBox.new()
  tray_power.margin_start = 30
  tray_power.margin_end = 10
  tray_power.margin_top = 105

  local function create_icon_label(glyph)
    local label = Gtk.Label.new(glyph)
    label:add_css_class("icon_font") 
    return label
  end

  local poweroff_button = Gtk.Button.new()
  poweroff_button:set_size_request(32, 32)
  poweroff_button:set_child(create_icon_label("")) 
  poweroff_button:add_css_class("tray_button")

  function poweroff_button:on_clicked()
    GLib.spawn_command_line_sync("systemctl poweroff")
  end

  local exit_button = Gtk.Button.new()
  exit_button:set_size_request(32, 32)
  exit_button:set_child(create_icon_label("")) 
  exit_button:add_css_class("tray_button")

  function exit_button:on_clicked()
    GLib.spawn_command_line_sync("swaymsg exit")
  end

  local lock_button = Gtk.Button.new()
  lock_button:set_size_request(32, 32)
  lock_button:set_child(create_icon_label("")) 
  lock_button:add_css_class("tray_button")

  tray_power.start_widget = poweroff_button
  tray_power.center_widget = exit_button
  tray_power.end_widget = lock_button

  local celdas = Gtk.Grid.new()
  celdas:attach(icon_pfp, 1, 1, 1, 1)
  celdas:attach(name_label, 2, 1, 1, 1)
  --celdas:attach(frase, 1, 2, 3, 1)
  celdas:attach(tray_power, 1, 3, 3, 1)

  center_box_dashboard:append(celdas)

  local h_right_box = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 10)
  h_right_box.margin_bottom = 10
  h_right_box.margin_start = 20
  h_right_box.margin_end = 20 
  h_right_box:append(create_weather_widget())
  h_right_box:append(create_sys_widget())
 
  local right_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 1)
  right_box:append(c_music_box())
  right_box:append(h_right_box) 

  local dashboard = Gtk.CenterBox.new()
  dashboard:set_size_request(0, 300)
  dashboard.hexpand = false
  dashboard.vexpand = false
  dashboard.start_widget = start_dashboard_main
  dashboard.center_widget = center_box_dashboard
  dashboard.end_widget = right_box 
  dashboard:add_css_class("dashboard")

  local revealer = Gtk.Revealer.new()
  revealer.child = dashboard
  revealer.reveal_child = false
  revealer.transition_duration = 500

  local motion_controller = Gtk.EventControllerMotion.new()
  
  function motion_controller:on_enter()
    revealer.reveal_child = true
    if conn then
      sway.run_command(conn, "gaps top all set 310")
    end
  end
  
  function motion_controller:on_leave()
    revealer.reveal_child = false
    if conn then
      sway.run_command(conn, "gaps top all set 10")
    end
  end

  center_box:append(revealer)

  local top_bar = Gtk.Overlay.new()
  top_bar:add_css_class("top_panel")
  top_bar:set_child(center_box)
  top_bar:add_controller(motion_controller)

  return top_bar
end

return M