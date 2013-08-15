--------------------------------------------
-- Author: Gregor Best                    --
-- Copyright 2009, 2010, 2011 Gregor Best --
--------------------------------------------

local string = {
    format = string.format
}
local setmetatable = setmetatable
local lib = {
    widget = require("obvious.lib.widget"),
    markup = require("obvious.lib.markup"),
    wlan   = require("obvious.lib.wlan")
}

module("obvious.wlan")

function format_decibel(link)
    local color = "#009000"
    if link < 20 and link > 5 then
        color = "#909000"
    elseif link <= 5 then
        color = "#900000"
    end
    return lib.markup.fg.color(color, "☢") .. string.format(" %02ddB", link)
end

function format_percent(link)
    local color = "#009000"
    if link < 50 and link > 10 then
        color = "#909000"
    elseif link <= 10 then
        color = "#900000"
    end
    return lib.markup.fg.color(color,"☢") .. string.format(" %03d%%", link)
end

local function get_data_source(device)
    local device = device or "wlan0"
    local data = {}

    data.device = device
    data.max = 100
    data.get = function (obj)
        return lib.wlan(obj.device)
    end

    local ret = lib.widget.from_data_source(data)
    -- Due to historic reasons, this widget defaults to a textbox with
    -- a "special" format.
    ret:set_type("textbox")
    ret:set_format(format_percent)

    return ret
end

setmetatable(_M, { __call = function (_, ...) return get_data_source(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
