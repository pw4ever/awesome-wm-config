local shortcuts = {
  _NAME = "foggy.shortcuts"
}

local set_backlight = require('foggy.xrandr').actions.set_backlight
local get_output = require('foggy.menu').get_output

function shortcuts.inc_backlight(step, screen)
  local step = step or 5
  local screen = screen or mouse.screen
  local output = get_output(screen)
  local backlight = output.properties.BACKLIGHT
  
  local mag = (backlight.range[2] - backlight.range[1])
  local pct = (tonumber(backlight.value) - backlight.range[1]) / mag * 100
  pct = math.max(0, math.min(pct + step, 100))

  local value = backlight.range[1] + mag * pct / 100

  set_backlight(output.name, math.floor(value))
end

return shortcuts
