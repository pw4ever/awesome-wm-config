-----------------------------------------------------
-- Bluetooth widget for the awesome window manager --
-----------------------------------------------------
-- Author: Christian Kuka chritian@kuka.cc         --
-- Copyright 2010 Christian Kuka                   --
-- Licensed under GPLv2                            --
-----------------------------------------------------

local assert = assert
local string = string
local setmetatable = setmetatable
local table = table
local io = {
    popen = io.popen
}
local capi = {
        widget = widget,
        mouse = mouse
}

local naughty = require("naughty")
local awful = require("awful")

local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.bluetooth")

widget = capi.widget({
    type = "textbox",
    name = "tb_gps",
    align = "right"
})

widget.text = "⋊"

-- Major device classes
local classes = {
   x00 = "Misc",
   x01 = "Computer",
   x02 = "Phone",
   x03 = "Network",
   x04 = "Audio",
   x05 = "Peripheral",
   x06 = "Imaging",
   x1f = "Uncategorized"
}

-- Return device list
devices = {}
function get_data()
   return devices
end


-- Update device list
local function update()
   devices = {}
   local fd = io.popen("hcitool inq")
   if not fd then return end
   -- Inquery takes 10.5s
   for addr, cl in string.gfind(fd:read("*all"),"%s+([a-zA-Z0-9:]+)%s+clock offset: [a-z0-9]+%s+class: ([a-z0-9]+)") do
    local dev = {
         address = addr,
         class = classes[cl:sub(2,4)] or "Uncategorized"
      }
      table.insert(devices, dev)
   end
end

-- Show address and major device class
local function detail()
   local d = "Bluetooth Devices:"
   table.foreach(devices, function(i,dev)
                             d = d.."\n"..dev.address.."\t"..dev.class
                          end)
   naughty.notify({
                     text = d,
                     screen = capi.mouse.screen
                  })
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, detail)
))

lib.hooks.timer.register(60, 300, update)
lib.hooks.timer.start(update)

setmetatable(_M, { __call = function () return widget end })
