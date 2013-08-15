---------------------------------
-- Author: Andrei Thorp        --
-- Copyright 2010 Andrei Thorp --
---------------------------------
-- Dependencies: setxkbmap (shell command)
-- Ideas:
-- * user specified rewrite table: convert us(dvorak) to "Dvorak"
-- * use formatting system to allow people to format their text widgets
-- * allow the user to override the text widget with some other widget
-- * filter out the current layout from the menu that appears on click
-- * let user configure the quick update delay (1 second) in case their
--   computer is unusually slow or quick or something

local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local io = {
    popen = io.popen
}
local awful = require("awful")
local wibox = require("wibox")
local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

local defaults = {}
defaults.layouts = {}
defaults.menu = nil
defaults.widget = wibox.widget.textbox()
defaults.widget:set_text("...")

-- Clone the defaults to the used settings
local settings = {}
for key, value in pairs(defaults) do
    settings[key] = value
end

module("obvious.keymap_switch")

-- Updates once after a short delay and then unregisters its timer
local function delayed_update_once(start)
    if start == true then
        lib.hooks.timer.register(1, 1, delayed_update_once, "One-off update for keymap widget")
        lib.hooks.timer.start(delayed_update_once)
    else
        update()
        lib.hooks.timer.unregister(delayed_update_once)
    end
end

setup_done = false
local function init_once()
    if setup_done then
        return
    end
    lib.hooks.timer.register(5, 60, update, "Update for the keymap widget")
    lib.hooks.timer.start(update)
    delayed_update_once(true)
    setup_done = true
end

local function init(widget)
    init_once()

    -- Use the default widget if not specified
    if widget then
        settings.widget = widget
    end

    -- Reconfigure the menu immediately
    set_layouts(settings.layouts)

    -- Set up the on-click menu event
    settings.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() settings.menu:toggle() end)
        ))

    return settings.widget
end

-- Returns the current keymap, as discovered from setxkbmap
local function get_current_keymap()
    local fd = io.popen("setxkbmap -print")
    if not fd then return end

    for line in fd:lines() do
        if line:match("xkb_symbols") then
            local keymap = line:match("\+.*\+")

            fd:close()
            if not keymap then
                return "unknown layout"
            else
                return keymap:sub(2, -2)
            end
        end
    end

    fd:close()
    return "unknown layout"
end

local function switch_keymap(layout_string)
    awful.util.spawn("setxkbmap \"" .. layout_string .. "\"")
    delayed_update_once(true)
end

function set_layouts(layouts_table)
    settings.layouts = layouts_table or settings.layouts

    newitems = {}
    for index, value in ipairs(settings.layouts) do
        newitems[index] = { value, function() switch_keymap(value) end }
    end

    settings.menu = awful.menu.new({
        id = "keymap_switch",
        items = newitems
    })
end

function update()
    settings.widget:set_markup(get_current_keymap())
end

setmetatable(_M, { __call = function() return init(settings.widget) end }) -- TODO let the user specify widget here
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
