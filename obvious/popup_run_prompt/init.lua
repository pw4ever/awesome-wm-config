------------------------------------------
-- Author: Andrei "Garoth" Thorp        --
-- Copyright 2009 Andrei "Garoth" Thorp --
------------------------------------------

local mouse = mouse
local awful = require("awful")
local widget = widget
local screen = screen
local ipairs = ipairs
local pairs = pairs
local io = io
local beautiful = require("beautiful")
local lib = {
    hooks = require("obvious.lib.hooks")
}
local capi = {
    wibox = wibox
}

module("obvious.popup_run_prompt")

defaults = {}
-- Default is 1 for people without compositing
defaults.opacity = 1.0
defaults.prompt_string = "  Run~  "
defaults.prompt_font = nil
-- Whether or not the bar should slide up or just pop up
defaults.slide = false
-- Bar will be percentage of screen width
defaults.width = 0.6
-- Bar will be this high in pixels
defaults.height = 22
defaults.border_width = 1
-- When sliding, it'll move this often (in seconds)
defaults.move_speed = 0.02
-- When sliding, it'll move this many pixels per move
defaults.move_amount = 3
-- Default run function
defaults.run_function = awful.util.spawn
-- Default completion function
defaults.completion_function = awful.completion.shell
-- Default cache
defaults.cache = "/history"
-- Default position
defaults.position = "top"

-- Clone the defaults for the used settings
settings = {}
for key, value in pairs(defaults) do
    settings[key] = value
end

runwibox = {}
mypromptbox = {}
inited = false

-- We want to "lazy init" so that in case beautiful inits late or something,
-- this is still likely to work.
function ensure_init()
    if inited then
    return
    end

    inited = true
    for s = 1, screen.count() do
        mypromptbox[s] = widget({
            type = "textbox",
            name = "mypromptbox" .. s,
            align = "left"
        })

        runwibox[s] = capi.wibox({
            fg = beautiful.fg_normal,
            bg = beautiful.bg_normal,
            border_width = settings.border_width,
            border_color = beautiful.bg_focus,
        })
        set_default(s)
        runwibox[s].opacity = settings.opacity
        runwibox[s].visible = false
        runwibox[s].screen = s
        runwibox[s].ontop = true

        -- Widgets for prompt wibox
        runwibox[s].widgets = {
            mypromptbox[s],
            layout = awful.widget.layout.vertical.center
        }
    end
end

function set_default(s)
    runwibox[s]:geometry({
        width = screen[s].geometry.width * settings.width,
        height = settings.height,
        x = screen[s].geometry.x + screen[s].geometry.width *
            ((1 - settings.width) / 2),
        y = screen[s].geometry.y + screen[s].geometry.height -
            settings.height,
    })
end

function do_slide_up()
    local s = mouse.screen
    startgeom = runwibox[s]:geometry()
    runwibox[s]:geometry({
        y = startgeom.y - settings.move_amount
    })

    if runwibox[s]:geometry().y <= screen[s].geometry.y +
            screen[s].geometry.height - startgeom.height then
        set_default(s)
        lib.hooks.timer.stop(do_slide_up)
    end
end

function show_wibox(s)
    runwibox.screen = s
    if settings.slide == true then
        startgeom = runwibox[s]:geometry()
        -- changing visible property would reset wibox geometry to its defaults
        -- Might be 0 if position is set to "top"
        -- Thus the wibox has to be shown before setting its original slide up
        -- position. As a side effect, the top bar might blink if position is set
        -- to "top".
        runwibox[s].visible = true
        runwibox[s]:geometry({
            y = screen[s].geometry.y + screen[s].geometry.height,
        })
        if lib.hooks.timer.has(do_slide_up) then
            lib.hooks.timer.start(do_slide_up)
        else
            lib.hooks.timer.register(settings.move_speed,
                                     settings.move_speed*3,
                                     do_slide_up,
                                     "popup_run_prompt slide up")
        end
    else
        set_default(s)
        runwibox[s].visible = true
    end
end

function do_slide_down()
    local s = runwibox.screen
    startgeom = runwibox[s]:geometry()
    runwibox[s]:geometry({
        y = startgeom.y + settings.move_amount,
    })

    if runwibox[s]:geometry().y >= screen[s].geometry.y +
            screen[s].geometry.height then
        runwibox[s].visible = false
        lib.hooks.timer.stop(do_slide_down)
    end
end

function hide_wibox()
    local s = runwibox.screen or mouse.screen

    if settings.slide == true then
        runwibox[s].visible = true
        set_default(s)

        if lib.hooks.timer.has(do_slide_down) then
            lib.hooks.timer.start(do_slide_down)
        else
            lib.hooks.timer.register(settings.move_speed,
                                     settings.move_speed*3,
                                     do_slide_down,
                                     "popup_run_prompt slide down")
        end
    else
        set_default(s)
        runwibox[s].visible = false
    end
end

function run_prompt_callback()
    hide_wibox()
end

function run_prompt()
    ensure_init()
    show_wibox(mouse.screen)

    awful.prompt.run({ prompt = settings.prompt_string,
                       font = settings.prompt_font },
        mypromptbox[mouse.screen],
        settings.run_function,
        settings.completion_function,
        awful.util.getdir("cache") .. settings.cache,
        100,
        run_prompt_callback
    )
end

-- SETTINGS
function set_opacity(amount)
    settings.opacity = amount or defaults.opacity
    update_settings()
end

function set_prompt_string(string)
    settings.prompt_string = string or defaults.prompt_string
end

function set_prompt_font(font_string)
    settings.prompt_font = font_string or defaults.prompt_font
end

function set_slide(tf)
    settings.slide = tf or defaults.slide
end

function set_width(amount)
    settings.width = amount or defaults.width
    update_settings()
end

function set_height(amount)
    settings.height = amount or defaults.height
    update_settings()
end

function set_border_width(amount)
    settings.border_width = amount or defaults.border_width
    update_settings()
end

function set_move_speed(amount)
    settings.move_speed = amount or defaults.move_speed
end

function set_move_amount(amount)
    settings.move_amount = amount or defaults.move_amount
end

function set_run_function(fn)
    settings.run_function = fn or defaults.run_function
end

function set_completion_function(fn)
    settings.completion_function = fn or defaults.completion_function
end

function set_position(p)
    settings.position = p
end

function update_settings()
    for s, value in ipairs(runwibox) do
        value.border_width = settings.border_width
        set_default(s)
        runwibox[s].opacity = settings.opacity
    end
end

function set_cache(c)
    settings.cache = c or defaults.cache
end

