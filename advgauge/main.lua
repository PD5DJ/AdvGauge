---- ##########################################################################################################
---- #                                                                                                        #
---- # Advanced gauge for ETHOS                                                                               #
---- #                                                                                                        #
---- # Advanced Gauge widget with the possibility to act as a Lipo Voltage to Percentage gauge                #
---- #                                                                                                        #
---- # Compatible with any voltage source like Vfas, A1 , A2 , MLVSS and FLVSS Sensors                        #
---- # Gives a aproximate percentage of a Lipo battery pack left.                                             #
---- #                                                                                                        #
---- #                                                                                                        #
---- # License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html                                                #
---- #                                                                                                        #
---- # This program is free software; you can redistribute it and/or modify                                   #
---- # it under the terms of the GNU General Public License version 3 as                                      #
---- # published by the Free Software Foundation.                                                             #
---- #                                                                                                        #
---- #                                                                                                        #
---- # Björn Pasteuning / Hobby4life 2021                                                                     #
---- #                                                                                                        #
---- ##########################################################################################################


local version = "1.0.7"
local translations = {en="Advanced Gauge"}
local wait_end   = 0
local Cell_Count = 1
local state
local Voltage_Filtered  = 0   
local Battery_Connected = 0 
local Percent = 0

--state functions forward declaration
local wait, no_battery, done

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
end

local function create()
    return {
            color=lcd.RGB(0xEA, 0x5E, 0x00),
            lipo=false,
            alignment=0,
            PercReadout = true,
            factor=0,
            min=-1024,
            max=1024,
            value=0,
            cells=6,
            Gradient=false,
            ThresholdPerc=30,
            Threshold=false,
            Gradient_inverse=false,
            }
end

local function getPercentColor(percent,widget)
    if widget.Gradient_inverse then
      if widget.Threshold then
        if percent > widget.ThresholdPerc then
          return 0xFF, 0, 0
        end
      end
      g = math.floor(0xDF * ((100 - percent) / 100))
    else
      if widget.Threshold then
        if percent < widget.ThresholdPerc then
          return 0xFF, 0, 0
        end
      end
      g = math.floor(0xDF * (percent / 100))
    end
      r = 0xDF - g
      return r, g, 0  
end

function no_battery()
   -- wait for battery
   Battery_Connected    = 0

    if Voltage_Filtered > 3 then
       Battery_Connected    = 1
       --state      = wait_to_stabilize
       wait_end   = getTime() + 200
    end  --  end if

end

-------------------------------------------------------

function done()

    if Voltage_Filtered < 1 then
       state      = no_battery
       Battery_Connected    = 0
    end  -- end if

end



local function CalcPercent(Voltage_Source, Cell_Count)

    
     -- the following table of percentages has 121 percentage values ,
     -- starting from 3.0 V to 4.2 V , in steps of 0.01 V 
    Voltage_Filtered = Voltage_Filtered * 0.9  +  Voltage_Source * 0.1
 
    local Percent_Table = 
    {0  , 1  , 1  ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 , 
     2  , 2  , 2  ,  2 ,  2 ,  2 ,  2 ,  2 ,  2 ,  2 ,  3 ,  3 ,  3 ,  3 ,  3 ,  3 ,  3 ,  3 ,  3 ,  3 , 
     4  , 4  , 4  ,  4 ,  4 ,  4 ,  4 ,  4 ,  5 ,  5 ,  5 ,  5 ,  5 ,  5 ,  6 ,  6 ,  6 ,  6 ,  6 ,  6 , 
     7  , 7  , 7  ,  7 ,  8 ,  8 ,  9 ,  9 , 10 , 12 , 13 , 14 , 17 , 19 , 20 , 22 , 23 , 26 , 28 , 30 , 
     33 , 36 , 39 , 42 , 45 , 48 , 51 , 54 , 57 , 58 , 60 , 62 , 64 , 66 , 67 , 69 , 70 , 72 , 74 , 75 , 
     77 , 78 , 80 , 81 , 82 , 84 , 85 , 86 , 86 , 87 , 88 , 89 , 91 , 92 , 94 , 95 , 96 , 97 , 97 , 99 , 100  }
   

    if state == nil then state = no_battery end 
     
    if Cell_Count > 0 then 

      local Voltage_Cell    = 3
      local Battery_Percent = 0
      local Table_Index     = 1
      
      Voltage_Source = Voltage_Source * 100
      
      Voltage_Cell      = Voltage_Source / Cell_Count 
      Table_Index       = math.floor(Voltage_Cell - 298 )
      Battery_Connected = 1     

      if Table_Index    > 120 then  Table_Index = 120 end  --## check for index bounds
      if Table_Index    <   1 then  Table_Index =   1 end

      Battery_Percent   = Percent_Table[Table_Index]  
      
      return Battery_Percent
    end
  
end


local function paint(widget)
    local w, h = lcd.getWindowSize()

    if widget.source == nil then
        return
    end
    
    if widget.value == nil then
        return
    end    

    -- Define positions
    if h < 50 then
        lcd.font(FONT_XS)
    elseif h < 80 then
        lcd.font(FONT_S)
    elseif h > 170 then
        lcd.font(FONT_XL)
    else
        lcd.font(FONT_STD)
    end
    text_w, text_h = lcd.getTextSize("")
    box_top = text_h
    box_height = h - box_top - 4
    box_bottom = h - 4
    box_left = 4
    box_width = w - 8

    -- Source name and value
    lcd.drawText(box_left, 0, widget.source:name())
    lcd.drawText(box_left + box_width, 0, widget.source:stringValue(), RIGHT)
    

    
    
    -- Compute percentage
    if widget.lipo then
      Percent = CalcPercent(widget.value, widget.cells)
    else
      Percent = (widget.value - widget.min) / (widget.max - widget.min) * 100  
    end
        
    -- Limit excess output    
    if Percent > 100 then
        Percent = 100
    elseif Percent < 0 then
        Percent = 0
    end

    -- Gauge background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge color
    if widget.Gradient then
      lcd.color(lcd.RGB(getPercentColor(Percent,widget)))
    else
      lcd.color(widget.color)
    end

    -- Gauge Percentage to width calculation
    if widget.alignment == 1 then
      gauge_height = math.floor((((box_height - 2) / 100) * Percent) + 2)
      -- Gauge bar vertical
      lcd.drawFilledRectangle(box_left, (box_bottom - gauge_height) , box_width, gauge_height)       
    else
      gauge_width = math.floor((((box_width - 2) / 100) * Percent) + 2)
      -- Gauge bar horizontal
      lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)
    end
    
    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left +1, box_top +1 , box_width -2, box_height -2)

    -- Gauge percentage
    if widget.PercReadout then
      lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2, math.floor(Percent).."%", CENTERED)
    end
    
end

local function wakeup(widget)
    if widget.source then
      local newValue = widget.source:value()


        
        if widget.lipo == false then
          if widget.factor == 1 then
            newValue = newValue * 100
          elseif widget.factor == 2 then
            newValue = newValue * 10
          elseif widget.factor == 3 then
            newValue = newValue / 10
          elseif widget.factor == 4 then
            newValue = newValue / 100
          end
        end
        
        if widget.value ~= newValue then
            widget.value = newValue
            lcd.invalidate()
        end
    end
end

local function configure(widget)
    -- Source choice
    line = form.addLine("Source")
    form.addSourceField(line, form.getFieldSlots(line)[0], function() return widget.source end, function(value) widget.source = value end)

    -- Alignment
    line = form.addLine("Alignment")
    local field_alignment = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"Horizontal", 0}, {"Vertical", 1}}, function() return widget.alignment end, function(value) widget.alignment = value end)

    line = form.addLine("Percentage Visbible")
    local field_PercReadout = form.addBooleanField(line, form.getFieldSlots(line)[0], function() return widget.PercReadout end, function(value) widget.PercReadout = value end)
    
    
    -- Color
    line = form.addLine("Gauge Color")
    widget.field_color = form.addColorField(line, nil, function() return widget.color end, function(color) widget.color = color end)
    widget.field_color:enable(not widget.lipo)
    
 -- Gradient
    line = form.addLine("Color Gradient")
    local field_Gradient = form.addBooleanField(line, form.getFieldSlots(line)[0],
      function() return widget.Gradient end,
        function(value)
          widget.Gradient = value
            widget.field_color:enable(not value)
            widget.field_Threshold:enable(value)
            widget.field_Gradient_inverse:enable(value)
        end)     
    
    -- Gradient Inverse
    line = form.addLine("Gradient Inverse")
    local Gradient_inverse_slots = form.getFieldSlots(line, {0})
    widget.field_Gradient_inverse = form.addBooleanField(line, form.getFieldSlots(line)[0], function() return widget.Gradient_inverse end, function(value) widget.Gradient_inverse = value end) 
    widget.field_Gradient_inverse:enable(widget.Gradient)
    
 -- Use Red Threshold
    line = form.addLine("Red Threshold")
    local  Theshold_slots = form.getFieldSlots(line, {0})
    widget.field_Threshold = form.addBooleanField(line, form.getFieldSlots(line)[0],
      function() return widget.Threshold end,
        function(value)
          widget.Threshold = value
            widget.field_ThresholdPerc:enable(value)
        end)     
    widget.field_Threshold:enable(widget.Gradient)
    
    -- Threshold
    line = form.addLine("Threshold %")
    local ThresholdPerc_slots = form.getFieldSlots(line, {0})
    widget.field_ThresholdPerc = form.addNumberField(line, ThresholdPerc_slots[1], 0, 100, function() return widget.ThresholdPerc end, function(value) widget.ThresholdPerc = value end);
    widget.field_ThresholdPerc:enable(widget.Theshold)
    
    -- Range Min & Max
    line = form.addLine("Range")
    local slots = form.getFieldSlots(line, {0, "-", 0})
    widget.field_min = form.addNumberField(line, slots[1], -1024, 1024, function() return widget.min end, function(value) widget.min = value end);
    widget.field_min:enable(not widget.lipo)
    form.addStaticText(line, slots[2], "-")
    widget.field_max = form.addNumberField(line, slots[3], -1024, 1024, function() return widget.max end, function(value) widget.max = value end);
    widget.field_max:enable(not widget.lipo)


    -- Range Multiplier
    line = form.addLine("Range Multiplier")
    widget.field_factor = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"x 100", 1}, {"x 10",2}, {"default", 0}, {"/ 10", 3}, {"/ 100", 4}}, function() return widget.factor end, function(value) widget.factor = value end)   

    -- LiPo
    line = form.addLine("Lipo Calculation")
    local field_lipo = form.addBooleanField(line, form.getFieldSlots(line)[0],
      function() return widget.lipo end,
        function(value)
            widget.lipo = value
            widget.field_min:enable(not value)
            widget.field_max:enable(not value)
            widget.field_color:enable(not value)
            widget.field_factor:enable(not value)
            widget.field_cells:enable(value)
        end)

    
    -- Cell count
    line = form.addLine("Cells")
    widget.field_cells = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"1 Cell", 1}, {"2 Cells", 2}, {"3 Cells", 3}, {"4 Cells", 4}, {"5 Cells", 5}, {"6 Cells", 6}, {"7 Cells", 7}, {"8 Cells", 8}, {"9 Cells", 9}, {"10 Cells", 10}, {"11 Cells", 11}, {"12 Cells", 12}, {"13 Cells", 13}, {"14 Cells", 14}}, function() return widget.cells end, function(value) widget.cells = value end)
    widget.field_cells:enable(widget.lipo)   
    
    -- Visibility of fields entering configuration
    if widget.lipo == 1 then
      widget.field_min:enable(false)
      widget.field_max:enable(false)
      widget.field_color:enable(false)
      widget.field_cells:enable(true)  
      widget.field_factor:enable(false)
    else
      widget.field_min:enable(true)
      widget.field_max:enable(true)
      widget.field_color:enable(true)
      widget.field_cells:enable(false)  
      widget.field_factor:enable(true)
    end
    
end

local function read(widget)
    widget.source = storage.read("source")
    widget.min = storage.read("min")
    widget.max = storage.read("max")
    widget.color = storage.read("color")
    widget.cells = storage.read("cells")
    widget.lipo = storage.read("lipo")
    widget.alignment = storage.read("alignment")
    widget.PercReadout = storage.read("PercReadout")
    widget.factor = storage.read("factor")
    widget.Gradient = storage.read("Gradient")
    widget.Threshold = storage.read("Threshold")    
    widget.ThresholdPerc = storage.read("ThresholdPerc")
    widget.Gradient_inverse = storage.read("Gradient inverse")
end

local function write(widget)
    storage.write("source",widget.source)
    storage.write("min",widget.min)
    storage.write("max",widget.max)
    storage.write("color",widget.color)
    storage.write("cells",widget.cells)
    storage.write("lipo",widget.lipo)
    storage.write("alignment",widget.alignment)
    storage.write("PercReadout",widget.PercReadout)
    storage.write("factor",widget.factor)
    storage.write("Gradient",widget.Gradient)
    storage.write("Threshold",widget.Threshold)
    storage.write("ThresholdPerc",widget.ThresholdPerc)
    storage.write("Gradient Inverse",widget.Gradient_inverse)
end

local function init()
    system.registerWidget({key="agauge", name=name, create=create, paint=paint, wakeup=wakeup, configure=configure, menu=menu, read=read, write=write})
end

return {init=init}
