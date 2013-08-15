-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local beautiful = require("beautiful")
local awful = {
    widget = require("awful.widget")
}
local setmetatable = setmetatable

module("obvious.lib.widget.progressbar")

function progressbar(layout)
    local theme = beautiful.get()
    local width = theme.progressbar_width or theme.widget_width or 8
    local color = theme.progressbar_fg_color or theme.widget_fg_color or theme.fg_normal
    local back  = theme.progressbar_bg_color or theme.widget_bg_color or theme.bg_normal
    local border= theme.progressbar_border or theme.widget_border or theme.border_normal

    local widget = awful.widget.progressbar({ layout = layout })
    widget:set_vertical(true)

    widget:set_width(width)
    widget:set_color(color)
    widget:set_background_color(back)
    widget:set_border_color(border)

    return widget
end

function create(data, layout)
    local widget = progressbar(layout)

    widget.update = function(widget)
        -- TODO: We don't support data sources without a fixed upper bound
        local max = widget.data.max or 1
        local val = widget.data:get() or max
        widget:set_value(val / max)
    end

    widget.data = data

    return widget
end

setmetatable(_M, { __call = function (_, ...) return progressbar(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
