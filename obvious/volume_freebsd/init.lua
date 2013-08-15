--------------------------------
-- Author: Gregor Best        --
-- Copyright 2009 Gregor Best --
--------------------------------

local setmetatable = setmetatable
local tonumber = tonumber
local pairs = pairs
local io = {
    popen = io.popen
}
local string = {
    match  = string.match,
    find   = string.find,
    format = string.format
}
local table = {
    insert = table.insert
}
local capi = {
    widget = widget,
}
local awful = require("awful")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.volume_freebsd")

local objects = { }

function get_data(channel)
    local rv = { }
    local fd = io.popen("mixer " .. channel)
    if not fd then return end
    local status = fd:read("*all")
    fd:close()

    rv.volume = tonumber(status:match(" +(%d?%d?%d)"))
    rv.mute = false

    local fd = io.popen("sysctl dev.acpi_ibm.0.mute")
    if fd then
        if tonumber(fd:read("*all"):match(": (%d)")) == 1 then
            rv.mute = true
        end
    end
    return rv
end

local function update(obj)
    local status = get_data(obj.channel) or { volume = 0, mute = true }

    local color = "#009000"
    if status.mute then
        color = "#900000"
    end
    obj.widget.text = lib.markup.fg.color(color, "☊") .. string.format(" %03d%%", status.volume)
end

local function update_by_values(channel)
    for i, v in pairs(objects) do
        if v.channel == channel then
            update(v)
        end
    end
end

function raise(channel, v)
    v = v or 1
    awful.util.spawn("mixer " .. channel .. " +" .. v, false)
    update_by_values(channel)
end

function lower(channel, v)
    v = v or 1
    awful.util.spawn("mixer " .. channel .. " -" .. v, false)
    update_by_values(channel)
end

local function create(_, channel)
    local channel = channel or "vol"

    local obj = { channel = channel }

    local widget = capi.widget({ type  = "textbox" })
    obj.widget = widget
    obj[1] = widget
    obj.update = function() update(obj) end

    widget:buttons(awful.util.table.join(
        awful.button({ }, 4, function () raise(obj.channel, 1) obj.update() end),
        awful.button({ }, 5, function () lower(obj.channel, 1) obj.update() end),
        awful.button({ "Shift" }, 4, function () raise(obj.channel, 10) obj.update() end),
        awful.button({ "Shift" }, 5, function () lower(obj.channel, 10) obj.update() end),
        awful.button({ "Control" }, 4, function () raise(obj.channel, 5) obj.update() end),
        awful.button({ "Control" }, 5, function () lower(obj.channel, 5) obj.update() end)
    ))

    obj.set_layout  = function(obj, layout) obj.layout = layout                       return obj end
    obj.set_channel = function(obj, id)     obj.channel = id             obj.update() return obj end
    obj.raise       = function(obj, v) raise(obj.channel, v) return obj end
    obj.lower       = function(obj, v) lower(obj.channel, v) return obj end

    obj.update()
    lib.hooks.timer.register(10, 30, obj.update, "Update for the volume widget")
    lib.hooks.timer.start(obj.update)

    table.insert(objects, obj)
    return obj
end

setmetatable(_M, { __call = create })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
