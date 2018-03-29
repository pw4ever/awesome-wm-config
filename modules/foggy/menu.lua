local xinerama = require('foggy.xinerama')
local xrandr = require('foggy.xrandr')
local awful = require('awful')
local naughty = require('naughty')
local edid = require('foggy.edid')

local menu = { mt = {}, _NAME = "foggy.menu" }

local function get_output(screen_num)
  local heads = xinerama.info().heads
  local xrinfo = xrandr.info()
  -- awesome always uses xinerama screen order, but 1-numbered
  local xs = heads[string.format("%d", screen_num - 1)]
  -- probably horribly wrong on advanced setups:
  -- the current xrandr output is the one that matches current screen's resolution + offset
  local co = nil
  for name, output in pairs(xrinfo.outputs) do
    if output.connected and output.on then
      if (output.resolution[0] == xs.resolution[0]) and (output.resolution[1] == xs.resolution[1])
        and (output.offset[0] == xs.offset[0] and output.offset[1] == xs.offset[1]) then
        co = output 
      end
    end
  end
  return co
end

local function output_name(co)
  if co.edid ~= "" then
    local monitor_name = edid.monitor_name(co.edid)
    if monitor_name then
      return co.name .. " (" .. edid.monitor_name(co.edid) .. ")"
    else
      return co.name
    end
  else
    return co.name
  end
end

local function build_transformation_menu(co)
  local transmenu = {}
  local at = co.available_transformations
  local ct = co.transformations

  for op, available in pairs(at.rotations) do
    if available then
      local flags = ''
      if ct.rotations[op] then
        flags = ' ✓'
      end
      transmenu[#transmenu + 1] = { string.format('rotate %s%s', op, flags), function() xrandr.actions.set_rotate(co.name, op) end }
    end
  end

  for op, available in pairs(at.reflections) do
    if available then
      local flags = ''
      if ct.reflections[op] then
        flags = ' ✓'
      end
      transmenu[#transmenu + 1] = { string.format('reflect %s%s', op, flags), function() xrandr.actions.set_reflect(co.name, op) end }
    end
  end

  return transmenu
end

local function build_resolution_menu(co)
  local resmenu = { { '&auto', function() xrandr.actions.auto_mode(co.name) end } }
  for i, mode in ipairs(co.modes) do
    local prefix = ' '
    local suffix = ''
    if mode == co.current_mode then
      prefix = '✓'
    end
    if mode == co.default_mode then
      suffix = ' *'
    end
    resmenu[#resmenu + 1] = { string.format('%s%dx%d@%2.0f%s', prefix, mode[1], mode[2], mode[3], suffix), function() xrandr.actions.set_mode(co.name, mode) end }
  end

  return resmenu
end

local function build_position_menu(co)
  local posmenu = {}
  local other_outputs = {}
  for name, _out in pairs(xrandr.info().outputs) do
    if name ~= co.name and _out.connected and _out.on then
      other_outputs[#other_outputs + 1] = name
    end
  end

  for _, dir in ipairs({ "left-of", "right-of", "above", "below", 'same-as' }) do
    local relmenu = {}
    for _, name in ipairs(other_outputs) do
      relmenu[#relmenu + 1] = { name, function() xrandr.actions.set_relative_pos(co.name, dir, name) end }
    end
    posmenu[#posmenu + 1] = { dir, relmenu }
  end

  return posmenu
end

local function build_backlight_menu(current_output)
  local thisout = current_output
  -- NOTE: how does this property name vary across drivers?
  local backlight = thisout.properties.BACKLIGHT
  if backlight == nil then
    return nil
  end

  local low = backlight.range[1]
  local high = backlight.range[2]

  local blmenu = { }
  for pct = 100, 0, -10 do
    local v = low + (high - low) * (pct / 100.0)
    blmenu[#blmenu + 1] = { pct .. '%', function() xrandr.actions.set_backlight(thisout.name, math.floor(v)) end }
  end

  return blmenu
end

local function build_properties_menu(current_output)
  local thisout = current_output
  local pmenu = {}
  
  for propname, propdef in pairs(thisout.properties) do
    if propname:upper() ~= "BACKLIGHT" and (propdef.supported or propdef.range) then
      local submenu = { }
      if propdef.supported then
        for _, value in ipairs(propdef.supported) do
          submenu[#submenu + 1] = { value, function() xrandr.actions.set_property(thisout.name, propname, value) end }
        end
      elseif propdef.range then
        local low = propdef.range[1]
        local high = propdef.range[2]

        for pct = 100, 0, -10 do
          local v = low + (high - low) * (pct / 100.0)
          submenu[#submenu + 1] = { pct .. '%', function() xrandr.actions.set_property(thisout.name, propname, math.floor(v)) end }
        end
      end

      pmenu[#pmenu + 1] = { propname, submenu }
    end
  end

  return pmenu
end

local function screen_menu(co, add_output_name)
  add_output_name = add_output_name or false

  local mainmenu = { }
  if co.on then
    local blmenu = build_backlight_menu(co)
    if blmenu then
      mainmenu[#mainmenu + 1] = { '&backlight', blmenu }
    end

    mainmenu[#mainmenu + 1] = { '&mode', build_resolution_menu(co) }
    mainmenu[#mainmenu + 1] = { '&transform', build_transformation_menu(co) }
    mainmenu[#mainmenu + 1] = { '&off', function() xrandr.actions.off(co.name) end }
    mainmenu[#mainmenu + 1] = { 'po&sition', build_position_menu(co) }

    if not co.primary then
      mainmenu[#mainmenu + 1] = { '&primary', function() xrandr.actions.set_primary(co.name) end }
    end
    mainmenu[#mainmenu + 1] = { 'p&roperties', build_properties_menu(co) }
  else
    mainmenu[#mainmenu + 1] = { '&on', function() xrandr.actions.auto_mode(co.name) end }
  end

  if add_output_name then
    table.insert(mainmenu, 1, { '[' .. output_name(co) .. ']' , nil })
  end

  mainmenu[#mainmenu + 1] = { 'i&dentify', function() xrandr.actions.identify_outputs() end }
  
  return mainmenu
end

local function build_menu(current_screen)
  local outputs = xrandr.info().outputs
  local thisout = get_output(current_screen)
  local scrn_menu = screen_menu(thisout, true)
  local visible = { [thisout.name] = true }
  -- iterate over outputs, not screens
  -- otherwise menu is bugged when cloning
  for name, output in pairs(outputs) do
    if output.connected and output.on and output.name ~= thisout.name then
      scrn_menu[#scrn_menu + 1] = { output_name(output), screen_menu(output, false) }
    end
  end
  -- add connected but disabled screens
  for name, output in pairs(outputs) do
    if output.connected and (not output.on) and (not visible[name]) then
      scrn_menu[#scrn_menu + 1] = { output_name(output), screen_menu(output, false) }
    end
  end
  return scrn_menu
end

function menu.menu(current_screen)
  current_screen = current_screen or mouse.screen.index
  local thismenu = build_menu(current_screen)
  awful.menu.new({ items = thismenu,
    theme = { width = 280 }}):show()
end

function menu.backlight(current_screen)
  current_screen = current_screen or mouse.screen.index
  local amenu = build_backlight_menu(current_screen)
  if amenu ~= nil then
    awful.menu(amenu):show()
  end
end

function menu.mt:__call(...)
  return menu.menu(...)
end

menu.get_output = get_output

return setmetatable(menu, menu.mt)
