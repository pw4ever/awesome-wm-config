-----------------------------------
-- Author: Eligio Becerra        --
-- Copyright 2009 Eligio Becerra --
-----------------------------------

local awful = require("awful")
local setmetatable = setmetatable
local tonumber = tonumber
local table = {
   insert = table.insert
}
local wibox = require("wibox")
local lib = {
   markup = require("obvious.lib.markup"),
   hooks = require("obvious.lib.hooks")
}

module("obvious.temp_info")

local widget = wibox.widget.textbox()

local colors = {
   ["normal"] = "#009000",
   ["warm"] = "#909000",
   ["hot"] = "#900000"
}

local function update()
   local d = awful.util.pread("acpi -t")
   local temp = { }
   for t in d:gmatch("Thermal %d+: %w+, (%d+.?%d*) degrees") do
      table.insert(temp, t)
   end

   local color = colors["hot"]
   if not temp[1] then
      widget:set_text 'no data'
      return
   end
   if tonumber(temp[1]) < 50 then
      color = colors["normal"]
   elseif tonumber(temp[1]) >= 50 and tonumber(temp[1]) < 60 then
      color = colors["warm"]
   end
   widget:set_markup(temp[1] .. " " .. lib.markup.fg.color(color, "C"))
end

lib.hooks.timer.register(5, 30, update)
lib.hooks.timer.stop(update)

setmetatable(_M, { __call = function ()
   lib.hooks.timer.start(update)
   update()
   return widget
end })

-- vim: filetype=lua:expandtab:shiftwidth=3:tabstop=3:softtabstop=3:encoding=utf-8:textwidth=80
