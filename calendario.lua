-- calendario.lua
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")
local GLib = lgi.require("GLib")
local GObject = lgi.require("GObject")

local M = {}

-- Tablas de días y meses
M.wdays = {"Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"}
M.wmonths = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", 
             "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"}

-- Funciones auxiliares
function M.dias_en_mes(mes, anio)
  local dias_por_mes = {
    [1] = 31, [3] = 31, [5] = 31, [7] = 31, [8] = 31, [10] = 31, [12] = 31,
    [4] = 30, [6] = 30, [9] = 30, [11] = 30
  }
  
  if mes == 2 then
    if (anio % 4 == 0 and anio % 100 ~= 0) or (anio % 400 == 0) then
      return 29
    else
      return 28
    end
  else
    return dias_por_mes[mes] or 31
  end
end

function M.obtener_dia_inicio(mes, anio)
  local primer_dia = os.time({year = anio, month = mes, day = 1})
  local fecha_info = os.date("*t", primer_dia)
  return fecha_info.wday
end

function M.crear_calendario(mes, anio)
  local f = os.date("*t")
  mes = mes or f.month
  anio = anio or f.year

  local calendario_box = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)
  calendario_box:add_css_class("box_dashboard")

  -- Encabezado
  local cal_mes = Gtk.Label.new(M.wmonths[mes] .. ", " .. anio)
  cal_mes.margin_start = 20
  cal_mes.margin_top = 20
  cal_mes.halign = Gtk.Align.START
  cal_mes:add_css_class("cal-header")

  -- Grid para días
  local cal_dias = Gtk.Grid.new()
  cal_dias.margin_start = 20
  cal_dias.margin_end = 20
  cal_dias.margin_bottom = 20

  -- Información del mes
  local total_dias = M.dias_en_mes(mes, anio)
  local dia_inicio = M.obtener_dia_inicio(mes, anio)
  local dia_actual = (mes == f.month and anio == f.year) and f.day or nil

  -- Llenar calendario
  local fila = 2
  local dia_numero = 1

  while dia_numero <= total_dias do
    for c = 1, 7 do
      if (fila == 2 and c < dia_inicio) or dia_numero > total_dias then
        -- Celda vacía
        local vacio = Gtk.Label.new("")
        vacio:add_css_class("cal-empty")
        cal_dias:attach(vacio, c, fila, 1, 1)
      else
        -- Celda con día
        local cal_dia = Gtk.Label.new(tostring(dia_numero))
        cal_dia:add_css_class("cal-day")

        if dia_numero == dia_actual then
          cal_dia:add_css_class("cal-today")
        end

        cal_dias:attach(cal_dia, c, fila, 1, 1)
        dia_numero = dia_numero + 1
      end
    end
    fila = fila + 1
  end

  calendario_box:append(cal_mes)
  calendario_box:append(cal_dias)

  return calendario_box
end

function M.updatable_calendar()
  local calendar_container = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
  local current_calendar = nil
    
  local function update_calendar()
    local f = os.date("*t")
    local new_calendar = M.crear_calendario(f.month, f.year)
        
    -- Reemplazar calendario actual
    if current_calendar then
      calendar_container:remove(current_calendar)
      current_calendar = nil
      collectgarbage("step") 
    end
        
    calendar_container:append(new_calendar)
    current_calendar = new_calendar
        
    return false
  end
    
  -- un minuto
  local function schedule_midnight_update()

        
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 60, function()
      update_calendar()
      schedule_midnight_update() 
      return false
    end)
  end
    
  current_calendar = M.crear_calendario()
  calendar_container:append(current_calendar)
  schedule_midnight_update()
    
  return calendar_container
end

return M