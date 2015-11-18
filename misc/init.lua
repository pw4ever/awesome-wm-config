package.path = package.path .. ";./?/init.lua;"

local awful = require("awful")
local naughty = require("naughty")

-- some miscellaneous functions
misc = {}

-- my own notification. Turn previous notification off if used again
misc.notify =  {}
misc.notify.togglelist = {}

function misc.notify.volume (options)
    local vol = "<span face='monospace'>" .. awful.util.pread("myscripts/showvol.sh") .. "</span>"
    options = awful.util.table.join(options, {
        preset = naughty.config.presets.normal,
        title="Volume Info",
        text=vol,
        timeout = 0,
        screen = mouse.screen,
    })
    misc.notify.togglelist.volnotify = naughty.notify(options)
end

function misc.notify.togglevolume ()
    if misc.notify.togglelist.volnotify then
        naughty.destroy(misc.notify.togglelist.volnotify)
        misc.notify.togglelist.volnotify = nil
        return
    end
    misc.notify.volume()
end



--misc.notify.volume = volnotify



misc.IO = {}
misc.Volume = {}
misc.Volume.step = "1%"
misc.Volume.control = "Master"

function misc.Volume.Change (Master, step, dire)
    awful.util.spawn("amixer sset " .. Master .. " " .. step .. dire)
    if misc.notify.togglelist.volnotify then
        misc.notify.volume({replaces_id = misc.notify.togglelist.volnotify.id})
    end
end

function misc.Volume.Up ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "+")
end

function misc.Volume.Down ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "-")
end
return misc
