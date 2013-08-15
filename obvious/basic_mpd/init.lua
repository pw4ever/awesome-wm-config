------------------------------------------
-- Author: Andrei "Garoth" Thorp        --
-- Copyright 2009 Andrei "Garoth" Thorp --
------------------------------------------

local setmetatable = setmetatable
local pairs = pairs
local type = type
local string = string
local awful = require("awful")
local wibox = require('wibox')
local naughty = require("naughty")
local lib = {
        mpd = require("obvious.lib.mpd"),
        markup = require("obvious.lib.markup"),
        hooks = require("obvious.lib.hooks"),
}

module("obvious.basic_mpd")

local defaults = {
        format = "$title - $album - $artist",
        length = 75,
        unknown = "(unknown)",
}
local settings = {}
for key, value in pairs(defaults) do
        settings[key] = value
end

local widget = wibox.widget.textbox()

connection = lib.mpd.new()

-- Utility function to handle the text for MPD
-- @param songinfo: a table with fields "artist", "album", "title" in text
-- @return formatted (settings.format) string to display on the widget. This
-- respects settings.length and tries to make fields as close to the same
-- lenghths as possible if shortening is required.
local function format_metadata(songinfo)
        format = settings.format or defaults.format

        if (settings.length or defaults.length) <= 0 then
                return ""
        end

        used_keys = {}
        local start, stop
        start = 1
        stop = 1
        while start do
                local key
                start, stop = string.find(format, "%$%w+", stop)
                key = string.match(format, "%$(%w+)", stop)
                if key then
                        if songinfo[key] then
                                used_keys[key] = songinfo[key]
                        else
                                used_keys[key] = settings.unknown or
                                                 defaults.unknown
                        end
                end
        end

        retval = ""
        while true do
                retval = string.gsub(format, "%$(%w+)", used_keys)
                if #retval > (settings.length or defaults.length) then
                        longest_key = nil
                        longest_value = ""
                        for key, value in pairs(used_keys) do
                                if #value > #longest_value then
                                        longest_key = key
                                        longest_value = value
                                end
                        end
                        if longest_key then
                                -- shorten the longest by 1
                                used_keys[longest_key] = string.sub( used_keys[longest_key],
                                                   1,
                                                   #longest_value - 1)
                        else
                                -- Seems like the format itself's too long
                                err = "obvious.basic_mpd: impossible to fit " ..
                                       "output into " .. (settings.length or
                                       defaults.length) .. " characters.\n" ..
                                       "Widget paused."
                                naughty.notify({ text = err, timeout = 0 })
                                lib.hooks.timer.stop(update)
                                return ""
                        end
                else
                        -- All good!
                        break
                end
        end
        return awful.util.escape(retval)
end

-- Updates the widget's display
function update()
        local status = connection:send("status")
        local now_playing, songstats

        if not status.state then
                now_playing = "Music Off"
                now_playing = lib.markup.fg.color("yellow", now_playing)
        elseif status.state == "stop" then
                now_playing = "Music Stopped"
        else
                songstats = connection:send("playlistid " .. status.songid)
                format = settings.format or defaults.format
                if type(format) == "string" then
                        now_playing = format_metadata(songstats)
                elseif type(format) == "function" then
                        now_playing = format(songstats)
                else
                        naughty.notify({ text = "obvious.basic_mpd: Invalid " ..
                                                "display format. Widget " ..
                                                "paused." })
                        lib.hooks.timer.stop(update)
                end
        end

        widget:set_markup(now_playing)
end
update()
lib.hooks.timer.register(1, 30, update, "basic_mpd widget refresh rate")

-- SETTINGS
-- Set the format string
-- @param format The format string
function set_format(format)
        settings.format = format or defaults.format
        update()
end

-- Set the widget's text max length
-- @param format The max length (in characters) of the widget's text
function set_length(length)
        settings.length = length or defaults.length
        update()
end

-- Set the string to use for unknown metadata
-- @param format The string to use for unknown metadata
function set_unknown(unknown)
        settings.unknown = unknown or defaults.unknown
        update()
end

setmetatable(_M, { __call = function () return widget end })
-- vim: filetype=lua:expandtab:shiftwidth=8:tabstop=8:softtabstop=8:encoding=utf-8:textwidth=80
