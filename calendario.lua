local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "4.0")

local M = {}

-- datos para días y meses
M.wdays = {"Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"}
M.wmonths = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"}

-- funciones auxiliares
function M.get_day(n_wday)
  return M.wdays[n_wday] or "none"
end

function M.get_month(n_wmonth)
  return M.wmonths[n_wmonth] or "none"
end


function M.dias_en_mes(mes, anio)
  local dias_por_mes = {
    [1] = 31, [3] = 31, [5] = 31, [7] = 31, [8] = 31, [10] = 31, [12] = 31,[4] = 30, [6] = 30, [9] = 30, [11] = 30
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
    
  -- encabezado 
  local cal_mes = Gtk.Label.new(M.get_month(mes)..", "..anio )
  cal_mes.margin_start = 20
  cal_mes.margin_top = 20
  cal_mes.halign = Gtk.Align.START
  cal_mes:add_css_class("cal-header")
    
  -- grid para los días
  local cal_dias = Gtk.Grid.new()
  cal_dias.margin_start = 20
  cal_dias.margin_end = 20
  cal_dias.margin_bottom = 20
  --cal_dias.row_spacing = 4
  --cal_dias.column_spacing = 10
    
    
  -- obtener información del mes
  local total_dias = M.dias_en_mes(mes, anio)
  local dia_inicio = M.obtener_dia_inicio(mes, anio)
  local dia_actual = (mes == f.month and anio == f.year) and f.day or nil
    
  -- llenar el calendario
  local fila = 2
  local dia_numero = 1
    
  while dia_numero <= total_dias do
    for c = 1, 7 do
      if (fila == 2 and c < dia_inicio) or dia_numero > total_dias then
        -- celda vacía
        local vacio = Gtk.Label.new("")
        vacio:add_css_class("cal-empty")
        cal_dias:attach(vacio, c, fila, 1, 1)
      else
        -- celda con día del mes
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

return M