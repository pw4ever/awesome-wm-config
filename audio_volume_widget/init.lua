-- https://github.com/esn89/volumetextwidget
local wibox = require("wibox")
local awful = require("awful")

local audio_volume_widget = {}
 
audio_volume_widget.widget = wibox.widget.textbox()
audio_volume_widget.widget:set_align("right")
 
function update_volume(widget)
   local fd = io.popen("amixer sget Master")
   local status = fd:read("*all")
   fd:close()
 
   -- local volume = tonumber(string.match(status, "(%d?%d?%d)%%")) / 100
   local volume = string.match(status, "(%d?%d?%d)%%")
   volume = string.format("% 3d", volume)
 
   status = string.match(status, "%[(o[^%]]*)%]")

   if string.find(status, "on", 1, true) then
       -- For the volume numbers
       volume = volume .. "%"
   else
       -- For the mute button
       volume = volume .. "M"
       
   end
   widget:set_markup("<span fgcolor='red'>|Vol:" .. volume .. "|</span>")
end
 
update_volume(audio_volume_widget.widget)
 
audio_volume_widget.timer = timer({ timeout = 0.2 })
audio_volume_widget.timer:connect_signal("timeout", 
  function () 
    update_volume(audio_volume_widget.widget) 
  end)
audio_volume_widget.timer:start()

return audio_volume_widget 
