local awful = require("awful")
local config_path = awful.util.getdir("config")
package.path = config_path .. "/?.lua;" .. package.path
package.path = config_path .. "/?/init.lua;" .. package.path
package.path = config_path .. "/modules/?.lua;" .. package.path
package.path = config_path .. "/modules/?/init.lua;" .. package.path

local math = require("math")
local gears = require("gears")
awful.client = require("awful.client")
awful.screen = require("awful.screen")
awful.mouse = require("awful.mouse")
awful.rules = require("awful.rules")
awful.menu = require("awful.menu")
awful.ewmh = require("awful.ewmh")
require("awful.autofocus")
require("awful.dbus")
require("awful.remote")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local xrandr = require("xrandr")
local foggy = require("foggy")

-- vicious widgets
local vicious = require("vicious")

-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("bashets")

-- utilities
local util = require("util")

-- universal arguments
local uniarg = require("uniarg")

local capi = {
    tag = tag,
    screen = screen,
    client = client,
    timer = timer,
}

local timer = require("gears.timer")

-- do not use letters, which shadow access key to menu entry
awful.menu.menu_keys.down = { "Down", ".", ">", "'", "\"", }
awful.menu.menu_keys.up = {  "Up", ",", "<", ";", ":", }
awful.menu.menu_keys.enter = { "Right", "]", "}", "=", "+", }
awful.menu.menu_keys.back = { "Left", "[", "{", "-", "_", }
awful.menu.menu_keys.exec = { "Return", "Space", }
awful.menu.menu_keys.close = { "Escape", "BackSpace", }

-- customization
customization = {}
customization.config = {}
customization.orig = {}
customization.func = {}
customization.default = {}
customization.option = {}
customization.timer = {}
customization.widgets = {}

customization.config.version = "4.0.12"
customization.config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. customization.config.version

customization.default.property = {
    layout = awful.layout.suit.floating,
    mwfact = 0.5,
    nmaster = 1,
    ncol = 1,
    min_opacity = 0.4,
    max_opacity = 1,
    default_naughty_opacity = 1,
    low_naughty_opacity = 0.90,
    normal_naughty_opacity = 0.95,
    critical_naughty_opacity = 1,
    minimal_client_width = 50,
    minimal_client_height = 50,
}

customization.default.compmgr = 'xcompmgr'
customization.default.compmgr_args = '-f -c -s'
customization.default.wallpaper_change_interval = 15

customization.option.wallpaper_change_p = true
customization.option.tag_persistent_p = true
customization.option.low_battery_notification_p = true

naughty.config.presets.low.opacity = customization.default.property.low_naughty_opacity
naughty.config.presets.normal.opacity = customization.default.property.normal_naughty_opacity
naughty.config.presets.critical.opacity = customization.default.property.critical_naughty_opacity

do
    local config_path = awful.util.getdir("config")
    bashets.set_script_path(config_path .. "/modules/bashets/")
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{
-- HACK! prevent Awesome start autostart items multiple times in a session
-- cause: in-place restart by awesome.restart, xrandr change
-- idea: 
-- * create a file awesome-autostart-once when first time "dex" autostart items (at the end of this file)
-- * only "rm" this file when awesome.quit

local cachedir = awful.util.getdir("cache")
local awesome_tags_fname = cachedir .. "/awesome-tags"
local awesome_autostart_once_fname = cachedir .. "/awesome-autostart-once-" .. os.getenv("XDG_SESSION_ID")
local awesome_client_tags_fname = cachedir .. "/awesome-client-tags-" .. os.getenv("XDG_SESSION_ID")

do

    awesome.connect_signal("exit", function (restart)
        local scrcount = screen.count()
        -- save number of screens, used for check proper tag recording
        do
            local f = io.open(awesome_tags_fname .. ".0", "w+")
            if f then
                f:write(string.format("%d", scrcount) .. "\n")
                f:close()
            end
        end
        -- save current tags
        for s = 1, scrcount do
            local f = io.open(awesome_tags_fname .. "." .. s, "w+")
            if f then
                local tags = awful.tag.gettags(s)
                for _, tag in ipairs(tags) do
                    f:write(tag.name .. "\n")
                end
                f:close()
            end
            f = io.open(awesome_tags_fname .. "-selected." .. s, "w+")
            if f then
                f:write(awful.tag.getidx() .. "\n")
                f:close()
            end
        end
        customization.func.client_opaque_off(nil) -- prevent compmgr glitches
        if not restart then
            awful.util.spawn_with_shell("rm -rf " .. awesome_autostart_once_fname)
            awful.util.spawn_with_shell("rm -rf " .. awesome_client_tags_fname)
            if not customization.option.tag_persistent_p then
                awful.util.spawn_with_shell("rm -rf " .. awesome_tags_fname .. '*')
            end
            bashets.stop()
        else -- if restart, save client tags
            -- save tags for each client
            awful.util.mkdir(awesome_client_tags_fname)
            -- !! avoid awful.util.spawn_with_shell("mkdir -p " .. awesome_client_tags_fname) 
            -- race condition (whether awesome_client_tags_fname is created) due to asynchrony of "spawn_with_shell"
            for _, c in ipairs(client.get()) do
                local client_id = c.pid .. '-' .. c.window
                local f = io.open(awesome_client_tags_fname .. '/' .. client_id, 'w+')
                if f then
                    for _, t in ipairs(c:tags()) do
                        f:write(t.name .. "\n")
                    end
                    f:close()
                end
            end

        end
    end)

    customization.orig.quit = awesome.quit
    awesome.quit = function ()
        local scr = awful.screen.focused()
        awful.prompt.run({prompt = "Quit (type 'yes' to confirm)? "},
        customization.widgets.promptbox[scr].widget,
        function (t)
            if string.lower(t) == 'yes' then
                customization.orig.quit()
            end
        end,
        function (t, p, n)
            return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
        end)
    end
end

do

    customization.orig.restart = awesome.restart
    awesome.restart = function ()
        local scr = awful.screen.focused()
        awful.prompt.run({prompt = "Restart (type 'yes' to confirm)? "},
        customization.widgets.promptbox[scr].widget,
        function (t)
            if string.lower(t) == 'yes' then
                customization.orig.restart()
            end
        end,
        function (t, p, n)
            return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
        end)
    end
end

-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
---[[

do
    local config_path = awful.util.getdir("config")
    local function init_theme(theme_name)
        local theme_path = config_path .. "/themes/" .. theme_name .. "/theme.lua"
        beautiful.init(theme_path)
    end

    init_theme("zenburn")

    awful.util.spawn_with_shell("hsetroot -solid '#000000'")

    -- randomly select a background picture
    --{{
    function customization.func.change_wallpaper()
        if customization.option.wallpaper_change_p then
            awful.util.spawn_with_shell("cd " .. config_path .. "/wallpaper/; ./my-wallpaper-pick.sh")
        end
    end

    customization.timer.change_wallpaper= timer({timeout = customization.default.wallpaper_change_interval})

    customization.timer.change_wallpaper:connect_signal("timeout", customization.func.change_wallpaper)

    customization.timer.change_wallpaper:connect_signal("property::timeout", 
    function ()
        customization.timer.change_wallpaper:stop()
        customization.timer.change_wallpaper:start()
    end
    )

    customization.timer.change_wallpaper:start()
    -- first trigger
    customization.func.change_wallpaper()
    --}}
end
--]]

-- This is used later as the default terminal and editor to run.

--{{
local tools = {
    terminal = "sakura",
    system = {
        filemanager = "pcmanfm",
        taskmanager = "lxtask",
    },
    browser = {
    },
    editor = {
    },
}

tools.browser.primary = os.getenv("BROWSER") or "firefox"
tools.browser.secondary = ({chromium="firefox", firefox="chromium"})[tools.browser.primary]

-- alternative: override
tools.browser.primary = "google-chrome-stable"
tools.browser.secondary = "firefox"

tools.editor.primary = os.getenv("EDITOR") or "gvim"
tools.editor.secondary = ({emacs="gvim", gvim="emacs"})[tools.editor.primary]

-- alternative: override
tools.editor.primary = "gvim"
tools.editor.secondary = "emacsclient -c -a emacs"

local myapp = nil
do
    local function build(arg)
        local current = {}
        local keys = {} -- keep the keys sorted
        for k, v in pairs(arg) do table.insert(keys, k) end
        table.sort(keys)

        for _, k in ipairs(keys) do
            v = arg[k]
            if type(v) == 'table' then
                table.insert(current, {k, build(v)})
            else
                table.insert(current, {v, v})
            end
        end
        return current
    end
    myapp = build(tools)
end
--}}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.fair,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
}
--[[
local layouts =
{
awful.layout.suit.floating,
awful.layout.suit.tile,
awful.layout.suit.tile.left,
awful.layout.suit.tile.bottom,
awful.layout.suit.tile.top,
awful.layout.suit.fair,
awful.layout.suit.fair.horizontal,
awful.layout.suit.spiral,
awful.layout.suit.spiral.dwindle,
awful.layout.suit.max,
awful.layout.suit.max.fullscreen,
awful.layout.suit.magnifier
}
--]]
-- }}}

--[[
-- {{{ Wallpaper
if beautiful.wallpaper then
for s = 1, screen.count() do
gears.wallpaper.maximized(beautiful.wallpaper, s, true)
end
end
-- }}}
--]]

-- {{{ Customized functions

customization.func.system_lock = function ()
    awful.util.spawn("xscreensaver-command -l")
end

customization.func.system_suspend = function ()
    awful.util.spawn("systemctl suspend")
end

customization.func.system_hibernate = function ()
    local scr = awful.screen.focused()
    awful.prompt.run({prompt = "Hibernate (type 'yes' to confirm)? "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        if string.lower(t) == 'yes' then
            awful.util.spawn("systemctl hibernate")
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
    end)
end

customization.func.system_hybrid_sleep = function ()
    local scr = awful.screen.focused()
    awful.prompt.run({prompt = "Hybrid Sleep (type 'yes' to confirm)? "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        if string.lower(t) == 'yes' then
            awful.util.spawn("systemctl hybrid-sleep")
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
    end)
end

customization.func.system_reboot = function ()
    local scr = awful.screen.focused()
    awful.prompt.run({prompt = "Reboot (type 'yes' to confirm)? "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        if string.lower(t) == 'yes' then
            awesome.emit_signal("exit", nil)
            awful.util.spawn("systemctl reboot")
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
    end)
end

customization.func.system_power_off = function ()
    local scr = awful.screen.focused()
    awful.prompt.run({prompt = "Power Off (type 'yes' to confirm)? "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        if string.lower(t) == 'yes' then
            awesome.emit_signal("exit", nil)
            awful.util.spawn("systemctl poweroff")
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
    end)
end

customization.func.app_finder = function ()
    awful.util.spawn("xfce4-appfinder")
end

-- {{ client actions

customization.func.client_focus_next = function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end

customization.func.client_focus_prev = function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end

customization.func.client_focus_urgent = awful.client.urgent.jumpto

customization.func.client_swap_next = function () awful.client.swap.byidx(  1) end

customization.func.client_swap_prev = function () awful.client.swap.byidx( -1) end

customization.func.client_move_next = function () util.client.rel_send(1) end

customization.func.client_move_prev = function () util.client.rel_send(-1) end

customization.func.client_move_to_tag = function () 
    local keywords = {}
    local scr = awful.screen.focused()
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Move client to tag: "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        local tag = util.tag.name2tag(t)
        if tag then
            awful.client.movetotag(tag)
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end

customization.func.client_toggle_tag = function (c) 
    local keywords = {}
    local scr = awful.screen.focused()
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    local c = c or client.focus
    awful.prompt.run({prompt = "Toggle tag for " .. c.name .. ": "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        local tag = util.tag.name2tag(t)
        if tag then
            awful.client.toggletag(tag)
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end

customization.func.client_toggle_titlebar = function ()  
  awful.titlebar.toggle(client.focus)
end

customization.func.client_raise = function (c)
  c:raise()
end

customization.func.client_fullscreen = function (c) 
  c.fullscreen = not c.fullscreen  
end

customization.func.client_maximize_horizontal = function (c) 
  c.maximized_horizontal = not c.maximized_horizontal
end

customization.func.client_maximize_vertical = function (c) 
  c.maximized_vertical = not c.maximized_vertical
end

customization.func.client_maximize = function (c) 
  c.maximized = not c.maximized
end

customization.func.client_minimize = function (c) 
  c.minimized = not c.minimized
end

do 

  -- closures for client_status
  -- client_status[client] = {sidelined = <boolean>, geometry= <client geometry>}
  local client_status = {}

  customization.func.client_sideline_left = function (c)
    local scr = screen[awful.screen.focused()]
    local workarea = scr.workarea
    if client_status[c] == nil then
      client_status[c] = {sidelined=false, geometry=nil}
    end
    if client_status[c].sidelined then
      if client_status[c].geometry then
        c:geometry(client_status[c].geometry)
      end
    else
      client_status[c].geometry = c:geometry()
      workarea.width = math.floor(workarea.width/2)
      c:geometry(workarea)
    end
    client_status[c].sidelined = not client_status[c].sidelined
  end

  customization.func.client_sideline_right = function (c)
    local scr = screen[awful.screen.focused()]
    local workarea = scr.workarea
    if client_status[c] == nil then
      client_status[c] = {sidelined=false, geometry=nil}
    end
    if client_status[c].sidelined then
      if client_status[c].geometry then
        c:geometry(client_status[c].geometry)
      end
    else
      client_status[c].geometry = c:geometry()
      workarea.x = workarea.x + math.floor(workarea.width/2)
      workarea.width = math.floor(workarea.width/2)
      c:geometry(workarea)
    end
    client_status[c].sidelined = not client_status[c].sidelined
  end

  customization.func.client_sideline_top = function (c)
    local scr = screen[awful.screen.focused()]
    local workarea = scr.workarea
    if client_status[c] == nil then
      client_status[c] = {sidelined=false, geometry=nil}
    end
    if client_status[c].sidelined then
      if client_status[c].geometry then
        c:geometry(client_status[c].geometry)
      end
    else
      client_status[c].geometry = c:geometry()
      workarea.height = math.floor(workarea.height/2)
      c:geometry(workarea)
    end
    client_status[c].sidelined = not client_status[c].sidelined
  end

  customization.func.client_sideline_bottom = function (c)
    local scr = screen[awful.screen.focused()]
    local workarea = scr.workarea
    if client_status[c] == nil then
      client_status[c] = {sidelined=false, geometry=nil}
    end
    if client_status[c].sidelined then
      if client_status[c].geometry then
        c:geometry(client_status[c].geometry)
      end
    else
      client_status[c].geometry = c:geometry()
      workarea.y = workarea.y + math.floor(workarea.height/2)
      workarea.height = math.floor(workarea.height/2)
      c:geometry(workarea)
    end
    client_status[c].sidelined = not client_status[c].sidelined
  end

  customization.func.client_sideline_extend_left = function (c, by)
    local cg = c:geometry()
    if by then
      cg.x = cg.x - by
      cg.width = cg.width + by
    else -- use heuristics
      local delta = math.floor(cg.x/7)
      if delta ~= 0 then
        cg.x = cg.x - delta
        cg.width = cg.width + delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_extend_right = function (c, by)
    local cg = c:geometry()
    if by then
      cg.width = cg.width + by
    else
      local workarea = screen[awful.screen.focused()].workarea
      local rmargin = math.max( (workarea.x + workarea.width - cg.x - cg.width), 0)
      local delta = math.floor(rmargin/7)
      if delta ~= 0 then
        cg.width = cg.width + delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_extend_top = function (c, by)
    local cg = c:geometry()
    if by then
      cg.y = cg.y - by
      cg.height = cg.height + by
    else
      local delta = math.floor(cg.y/7)
      if delta ~= 0 then
        cg.y = cg.y - delta
        cg.height = cg.height + delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_extend_bottom = function (c, by)
    local cg = c:geometry()
    if by then
      cg.height = cg.height + by
      else
    local workarea = screen[awful.screen.focused()].workarea
    local bmargin = math.max( (workarea.y + workarea.height - cg.y - cg.height), 0)
    local delta = math.floor(bmargin/7)
    if delta ~= 0 then
      cg.height = cg.height + delta
    end
      end
      c:geometry(cg)
  end

  customization.func.client_sideline_shrink_left = function (c, by)
    local cg = c:geometry()
    local min = customization.default.property.minimal_client_width
    if by then
      cg.width = math.max(cg.width - by, min)
    else
      local delta = math.floor(cg.width/11)
      if delta ~= 0 and cg.width > min then
        cg.width = cg.width - delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_shrink_right = function (c, by)
    local cg = c:geometry()
    local min = customization.default.property.minimal_client_width
    if by then
      local t = cg.x + cg.width
      cg.width = math.max(cg.width - by, min)
      cg.x = t - cg.width
    else
      local delta = math.floor(cg.width/11)
      if delta ~= 0 and cg.width > min then
        cg.x = cg.x + delta
        cg.width = cg.width - delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_shrink_top = function (c, by)
    local cg = c:geometry()
    local min = customization.default.property.minimal_client_height
    if by then
      cg.height = math.max(cg.height - by, min)
    else
      local delta = math.floor(cg.height/11)
      if delta ~= 0 and cg.height > min then
        cg.height = cg.height - delta
      end
    end
    c:geometry(cg)
  end

  customization.func.client_sideline_shrink_bottom = function (c, by)
    local cg = c:geometry()
    local min = customization.default.property.minimal_client_height
    if by then
      local t = cg.y + cg.width
      cg.height = math.max(cg.height - by, min)
      cg.y = t - cg.height
    else
      local delta = math.floor(cg.height/11)
      if delta ~= 0 and cg.height > min then
        cg.y = cg.y + delta
        cg.height = cg.height - delta
      end
    end
    c:geometry(cg)
  end

end

customization.func.client_opaque_less = function (c)
  local opacity = c.opacity - 0.1
  if opacity and opacity >= customization.default.property.min_opacity then
    c.opacity = opacity
  end
end

customization.func.client_opaque_more = function (c)
  local opacity = c.opacity + 0.1
  if opacity and opacity <= customization.default.property.max_opacity then
    c.opacity = opacity
  end
end

customization.func.client_opaque_off = function (c)
  awful.util.spawn_with_shell("pkill " .. customization.default.compmgr)
end

customization.func.client_opaque_on = function (c)
  awful.util.spawn_with_shell(customization.default.compmgr.. " " .. customization.default.compmgr_args)
end

customization.func.client_swap_with_master = function (c) 
  c:swap(awful.client.getmaster()) 
end

customization.func.client_toggle_top = function (c)
  c.ontop = not c.ontop
end

customization.func.client_toggle_sticky = function (c)
  c.sticky = not c.sticky
end

customization.func.client_kill = function (c)
  c:kill()
end

do
    local instance = nil 
    customization.func.client_action_menu = function (c)
        local clear_instance = function ()
            if instance then
                instance:hide()
                instance = nil
            end
        end
        if instance and instance.wibox.visible then
            clear_instance()
            return
        end
        c = c or client.focus
        instance = awful.menu({
            theme = {
                width = 200,
            },
            items = {
                { 
                    "&cancel", function () 
                        clear_instance()
                    end 
                },
                { 
                    "=== task action menu ===", function ()
                        clear_instance()
                    end
                },
                { 
                    "--- status ---", function ()
                        clear_instance()
                    end
                },
                {
                    "&raise", function () 
                        clear_instance()
                        customization.func.client_raise(c)
                    end
                },
                {
                    "&top", function () 
                        clear_instance()
                        customization.func.client_toggle_top(c)
                    end
                },
                {
                    "&sticky", function () 
                        clear_instance()
                        customization.func.client_toggle_sticky(c)    
                    end
                },
                {
                    "&kill", function () 
                        clear_instance()
                        customization.func.client_kill(c)
                    end
                },
                {
                    "toggle title&bar", function () 
                        clear_instance()
                        customization.func.client_toggle_titlebar(c)
                    end
                },
                { 
                    "--- focus ---", function ()
                        clear_instance()
                    end
                },
                {
                    "&next client", function () 
                        clear_instance()
                        customization.func.client_focus_next(c)
                    end
                },
                {
                    "&prev client", function () 
                        clear_instance()
                        customization.func.client_focus_prev(c)
                    end
                },
                {
                    "&urgent", function () 
                        clear_instance()
                        customization.func.client_focus_urgent(c)
                    end
                },
                { 
                    "--- tag ---", function ()
                        clear_instance()
                    end
                },
                {
                    "move to next tag", function () 
                        clear_instance()
                        customization.func.client_move_next(c)
                    end
                },
                {
                    "move to previous tag", function () 
                        clear_instance()
                        customization.func.client_move_prev(c)
                    end
                },
                {
                    "move to ta&g", function () 
                        clear_instance()
                        customization.func.client_move_to_tag(c)
                    end
                },
                {
                    "togg&le tag", function () 
                        clear_instance()
                        customization.func.client_toggle_tag(c)
                    end
                },
                { 
                    "--- geometry ---", function ()
                        clear_instance()
                    end
                },
                {
                    "&fullscreen", function () 
                        clear_instance()
                        customization.func.client_fullscreen(c)
                    end
                },
                {
                    "m&aximize", function () 
                        clear_instance()
                        customization.func.client_maximize(c)
                    end
                },
                {
                    "maximize h&orizontal", function () 
                        clear_instance()
                        customization.func.client_maximize_horizontal(c)
                    end
                },
                {
                    "maximize &vertical", function () 
                        clear_instance()
                        customization.func.client_maximize_vertical(c)
                    end
                },
                {
                    "m&inimize", function () 
                        clear_instance()
                        customization.func.client_minimize(c) 
                    end
                },
                {
                    "move to left", function () 
                        clear_instance()
                        customization.func.client_sideline_left(c) 
                    end
                },
                {
                    "move to right", function () 
                        clear_instance()
                        customization.func.client_sideline_right(c) 
                    end
                },
                {
                    "move to top", function () 
                        clear_instance()
                        customization.func.client_sideline_top(c) 
                    end
                },
                {
                    "move to bottom", function () 
                        clear_instance()
                        customization.func.client_sideline_bottom(c) 
                    end
                },
                {
                    "extend left", function () 
                        clear_instance()
                        customization.func.client_sideline_extend_left(c) 
                    end
                },
                {
                    "extend right", function () 
                        clear_instance()
                        customization.func.client_sideline_extend_right(c) 
                    end
                },
                {
                    "extend top", function () 
                        clear_instance()
                        customization.func.client_sideline_extend_top(c) 
                    end
                },
                {
                    "extend bottom", function () 
                        clear_instance()
                        customization.func.client_sideline_extend_bottom(c) 
                    end
                },
                {
                    "shrink left", function () 
                        clear_instance()
                        customization.func.client_sideline_shrink_left(c) 
                    end
                },
                {
                    "shrink right", function () 
                        clear_instance()
                        customization.func.client_sideline_shrink_right(c) 
                    end
                },
                {
                    "shrink top", function () 
                        clear_instance()
                        customization.func.client_sideline_shrink_top(c) 
                    end
                },
                {
                    "shrink bottom", function () 
                        clear_instance()
                        customization.func.client_sideline_shrink_bottom(c) 
                    end
                },
                { 
                    "--- opacity ---", function ()
                        clear_instance()
                    end
                },
                {
                    "&less opaque", function () 
                        clear_instance()
                        customization.func.client_opaque_less(c)
                    end
                },
                {
                    "&more opaque", function () 
                        clear_instance()
                        customization.func.client_opaque_more(c)
                    end
                },
                {
                    "opacity off", function () 
                        clear_instance()
                        customization.func.client_opaque_off(c)
                    end
                },
                {
                    "opacity on", function () 
                        clear_instance()
                        customization.func.client_opaque_on(c)
                    end
                },
                { 
                    "--- ordering ---", function ()
                        clear_instance()
                    end
                },
                {
                    "swap with master", function () 
                        clear_instance()
                        customization.func.client_swap_with_master(c)
                    end
                },
                {
                    "swap with next", function () 
                        clear_instance()
                        customization.func.client_swap_next(c)
                    end
                },
                {
                    "swap with prev", function () 
                        clear_instance()
                        customization.func.client_swap_prev(c)
                    end
                },
            }
        })
        instance:toggle({keygrabber=true})
    end
end

-- }}

-- {{ tag actions

customization.func.tag_add_after = function ()
    local focused = awful.screen.focused()
    local scr = focused
    local sel_idx = focused.selected_tag and focused.selected_tag.index or 0
    local t = util.tag.add(nil, 
    {
        screen = scr,
        index = sel_idx and sel_idx+1 or 1,
        layout = customization.default.property.layout,
        mwfact = customization.default.property.mwfact,
        nmaster = customization.default.property.nmaster,
        ncol = customization.default.property.ncol,
    })
end

customization.func.tag_add_before = function ()
    local focused = awful.screen.focused()
    local scr = focused.index
    local sel_idx = focused.selected_tag and focused.selected_tag.index or 1
    local t = util.tag.add(nil, 
    {
        screen = scr,
        index = sel_idx and sel_idx or 1,
        layout = customization.default.property.layout,
        mwfact = customization.default.property.mwfact,
        nmaster = customization.default.property.nmaster,
        ncol = customization.default.property.ncol,
    })
end

customization.func.tag_delete = function ()
    local sel = awful.screen.focused().selected_tag
    if sel then sel:delete() end
end

customization.func.tag_rename = function ()
    local focused = awful.screen.focused()
    local sel = focused.selected_tag
    util.tag.rename(sel)
end

customization.func.tag_view_prev = awful.tag.viewprev

customization.func.tag_view_next = awful.tag.viewnext

customization.func.tag_last = awful.tag.history.restore

customization.func.tag_goto = function () 
    local keywords = {}
    local scr = awful.screen.focused()
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Goto tag: "},
    customization.widgets.promptbox[scr].widget,
    function (t)
        local tag = util.tag.name2tag(t)
        if tag then
            awful.tag.viewonly(tag)
        end
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end)
end

customization.func.tag_move_forward = function () 
    util.tag.rel_move(awful.tag.selected(), 1) 
end

customization.func.tag_move_backward = function () 
    util.tag.rel_move(awful.tag.selected(), -1) 
end

customization.func.tag_move_screen = function (scrdelta) 
    local seltag = awful.tag.selected()
    local scrcount = capi.screen.count()
    if seltag then
        local s = awful.tag.getscreen(seltag) + scrdelta
        if s > scrcount then s = 1 elseif s < 1 then s = scrcount end
        awful.tag.setscreen(seltag, s)
        awful.tag.viewonly(seltag)
        awful.screen.focus(s)
    end
end

customization.func.tag_move_screen_prev = function ()
    customization.func.tag_move_screen(-1)
end

customization.func.tag_move_screen_next = function ()
    customization.func.tag_move_screen(1)
end

do
    local instance = nil
    customization.func.tag_action_menu = function (t)
        local clear_instance = function ()
            if instance then
                instance:hide()
                instance = nil
            end
        end
        if instance and instance.wibox.visible then
            clear_instance()
            return
        end
        t = t or awful.tag.selected()
        if t then
            instance = awful.menu({
                theme = {
                    width = 200,
                },
                items = {
                    { 
                        "&cancel", function () 
                            clear_instance()
                        end
                    },
                    { 
                        "=== tag action menu ===", function ()
                            clear_instance()
                        end
                    },
                    { 
                        "--- dynamic tagging ---", function ()
                            clear_instance()
                        end
                    },
                    {
                        "add tag &after current one", function () 
                            clear_instance()
                            customization.func.tag_add_after(t)
                        end
                    },
                    {
                        "add tag &before current one", function () 
                            clear_instance()
                            customization.func.tag_add_before(t)
                        end
                    },
                    {
                        "&delete current tag if empty", function () 
                            clear_instance()
                            customization.func.tag_delete(t)
                        end
                    },
                    {
                        "&rename current tag", function () 
                            clear_instance()
                            customization.func.tag_rename(t)
                        end
                    },
                    { 
                        "--- focus ---", function ()
                            clear_instance()
                        end
                    },
                    {
                        "&goto tag", function () 
                            clear_instance()
                            customization.func.tag_goto(t)
                        end
                    },
                    {
                        "view &previous tag", function () 
                            clear_instance()
                            customization.func.tag_view_prev(t)
                        end
                    },
                    {
                        "view &next tag", function () 
                            clear_instance()
                            customization.func.tag_view_next(t)
                        end
                    },
                    {
                        "view &last tag", function () 
                            clear_instance()
                            customization.func.tag_last(t)
                        end
                    },
                    { 
                        "--- ordering ---", function ()
                            clear_instance()
                        end
                    },
                    {
                        "move tag &forward", function () 
                            clear_instance()
                            customization.func.tag_move_forward()
                        end
                    },
                    {
                        "move tag &backward", function () 
                            clear_instance()
                            customization.func.tag_move_backward()
                        end
                    },
                    { 
                        "--- screen ---", function ()
                            clear_instance()
                        end
                    },
                    {
                        "move tag to pre&vious window", function () 
                            clear_instance()
                            customization.func.tag_move_screen_prev()
                        end
                    },
                    {
                        "move tag to ne&xt window", function () 
                            clear_instance()
                            customization.func.tag_move_screen_next()
                        end
                    },
                }
            })
            instance:toggle({keygrabber=true})
        end
    end
end

-- }}

-- {{ clients on tags

do
    local instance = nil
    customization.func.clients_on_tag = function ()
        local clear_instance = function ()
            if instance then
                instance:hide()
                instance = nil
            end
        end
        if instance and instance.wibox.visible then
            clear_instance()
            return
        end
        local clients = { 
            items = {},
            theme = { width = 400 },
        }
        local next = next
        local t = awful.tag.selected()
        if t then
            for _, c in pairs(t:clients()) do
                if c.focusable and c.pid ~= 0 then
                    table.insert(clients.items, {
                        c.name .. " ~" .. tostring(c.pid) or "",
                        function ()
                            clear_instance()
                            client.focus = c
                            c:raise()
                        end,
                        c.icon
                    })
                end
            end
            if next(clients.items) ~= nil then
                instance = awful.menu(clients)
                instance:toggle({keygrabber=true})
            end
        end
    end
end

customization.func.clients_on_tag_prompt = function () 
  local clients = {}
  local next = next
  local t = awful.tag.selected()
  if t then
    local keywords = {}
    local scr = awful.screen.focused()
    for _, c in pairs(t:clients()) do
      if c.focusable and c.pid ~= 0 then
        local k = c.name .. " ~" .. tostring(c.pid) or ""
        if k ~= "" then
          clients[k] = c
          table.insert(keywords, k)
        end
      end
    end
    if next(clients) ~= nil then
      awful.prompt.run({prompt = "Focus on client on current tag: "},
      customization.widgets.promptbox[scr].widget,
      function (t)
        local c = clients[t]
        if c then
          client.focus = c
          c:raise()
        end
      end,
      function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
      end)
    end
  end
end

do
    local instance = nil
    customization.func.all_clients = function ()
        local clear_instance = function ()
            if instance then
                instance:hide()
                instance = nil
            end
        end
        if instance and instance.wibox.visible then
            clear_instance()
            return
        end
        local clients = {
            items = {},
            theme = { width = 400},
        }
        local next = next
        for _, c in pairs(client.get()) do
            if c.focusable and c.pid ~= 0 then
                table.insert(clients.items, {
                    c.name .. " ~" .. tostring(c.pid) or "",
                    function ()
                        local t = c:tags()
                        if t then
                            awful.tag.viewonly(t[1])
                        end
                        clear_instance()
                        client.focus = c
                        c:raise()
                    end,
                    c.icon
                })
            end
        end
        if next(clients.items) ~= nil then
            instance = awful.menu(clients)
            instance:toggle({keygrabber=true})
        end
    end
end

customization.func.all_clients_prompt = function ()
  local clients = {}
  local next = next
  local keywords = {}
  local scr = awful.screen.focused()
  for _, c in pairs(client.get()) do
    if c.focusable and c.pid ~= 0 then
      local k = c.name .. " ~" .. tostring(c.pid) or ""
      if k ~= "" then
        clients[k] = c
        table.insert(keywords, k)
      end
    end
  end
  if next(clients) ~= nil then
    awful.prompt.run({prompt = "Focus on client from global list: "},
    customization.widgets.promptbox[scr].widget,
    function (t)
      local c = clients[t]
      if c then
        local t = c:tags()
        if t then
          awful.tag.viewonly(t[1])
        end
        client.focus = c
        c:raise()
      end
    end,
    function (t, p, n)
      return awful.completion.generic(t, p, n, keywords)
    end)
  end
end

do
    local instance = nil
    customization.func.systeminfo = function () 
        if instance then
            naughty.destroy(instance)
            instance = nil
            return
        end
        local info = "Version: " .. awesome.version 
        info = info ..  "\n" .. "Release: " .. awesome.release
        info = info ..  "\n" .. "Config: " .. awesome.conffile
        info = info ..  "\n" .. "Config Version: " .. customization.config.version 
        info = info ..  "\n" .. "Config Help: " .. customization.config.help_url
        if awesome.composite_manager_running then
            info = info .. "\n" .. "<span fgcolor='red'>a composite manager is running</span>"
        end
        local uname = util.pread("uname -a")
        if string.gsub(uname, "%s", "") ~= "" then
            info = info .. "\n" .. "OS: " .. string.gsub(uname, "%s+$", "")
        end
        -- remove color code from screenfetch output
        local archey = util.pread("screenfetch -N")
        if string.gsub(archey, "%s", "") ~= "" then
            info = info .. "\n\n<span face='monospace'>" .. archey .. "</span>"
        end
        info = string.gsub(info, "(%u[%a ]*:)%f[ ]", "<span color='red'>%1</span>")
        local tmp = awesome.composite_manager_running
        awesome.composite_manager_running = false
        instance = naughty.notify({
            preset = naughty.config.presets.normal,
            title="awesome info",
            text=info,
            timeout = 10,
            screen = awful.screen.focused(),
        })
        awesome.composite_manager_running = tmp
    end
end

do
    local instance = nil
    customization.func.help = function ()
        if instance then
            naughty.destroy(instance)
            instance = nil
            return
        end
        local text = ""
        text = text .. "You are running awesome <span fgcolor='red'>" .. awesome.version .. "</span> (<span fgcolor='red'>" .. awesome.release .. "</span>)"
        text = text .. "\n" .. "with config version <span fgcolor='red'>" .. customization.config.version .. "</span>"
        text = text .. "\n\n" .. "help can be found at the URL: <u>" .. customization.config.help_url .. "</u>"
        text = text .. "\n\n\n\n" .. "opening in <b>" .. tools.browser.primary .. "</b>..."
        instance = naughty.notify({
            preset = naughty.config.presets.normal,
            title="help about configuration",
            text=text,
            timeout = 20,
            screen = awful.screen.focused(),
        })
        awful.util.spawn_with_shell(tools.browser.primary .. " '" .. customization.config.help_url .. "'")
    end
end

-- }}

-- }}}

-- {{{ Menu

-- Create a launcher widget and a main menu
mysystemmenu = {
    --{ "manual", tools.terminal .. " -e man awesome" },
    { "&lock", customization.func.system_lock },
    { "&suspend", customization.func.system_suspend },
    { "hi&bernate", customization.func.system_hibernate },
    { "hybri&d sleep", customization.func.system_hybrid_sleep },
    { "&reboot", customization.func.system_reboot },
    { "&power off", customization.func.system_power_off }
}

-- Create a launcher widget and a main menu
myawesomemenu = {
    --{ "manual", tools.terminal .. " -e man awesome" },
    { "hotkeys", function() return false, hotkeys_popup.show_help end},
    { "&edit config", tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
    { "&restart", awesome.restart },
    { "forcibly restart", customization.orig.restart },
    { "&quit", awesome.quit },
    { "forcibly quit", function () customization.orig.quit() end },
}

mymainmenu = awful.menu({
  theme = { width=150, },
  items = {
    { "&system", mysystemmenu },
    { "app &finder", customization.func.app_finder },
    { "&apps", myapp },
    { "&terminal", tools.terminal },
    { "a&wesome", myawesomemenu, beautiful.awesome_icon },
    { "&client action", function () 
      customization.func.client_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "&tag action", function ()
      customization.func.tag_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients &on current tag", function ()
      customization.func.clients_on_tag()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients on a&ll tags", function ()
      customization.func.all_clients()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
  }
})

-- Keyboard map indicator and switcher
customization.widgets.keyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
customization.widgets.textclock = wibox.widget.textclock()

-- Launcher
customization.widgets.launcher = awful.widget.launcher({ 
    image = beautiful.awesome_icon,
    menu = mymainmenu,
})

-- }}}

-- {{{ Wibox
--customization.widgets.textclock = wibox.widget.textbox()
--bashets.register("date.sh", {widget=customization.widgets.textclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"}) -- http://awesome.naquadah.org/wiki/Bashets

-- vicious widgets: http://awesome.naquadah.org/wiki/Vicious

customization.widgets.cpuusage = awful.widget.graph()
customization.widgets.cpuusage:set_width(50)
customization.widgets.cpuusage:set_background_color("#494B4F")
customization.widgets.cpuusage:set_color({ 
  type = "linear", from = { 0, 0 }, to = { 10,0 }, 
  stops = { {0, "#FF5656"}, {0.5, "#88A175"}, {1, "#AECF96" }}})
vicious.register(customization.widgets.cpuusage, vicious.widgets.cpu, "$1", 5)                   
do
    local prog=tools.system.taskmanager
    local started=false
    customization.widgets.cpuusage:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end)
    ))
end

customization.widgets.memusage = wibox.widget.textbox()
vicious.register(customization.widgets.memusage, vicious.widgets.mem,
  "<span fgcolor='yellow'>$1% ($2MB/$3MB)</span>", 3)
do
    local prog=tools.system.taskmanager
    local started=false
    customization.widgets.memusage:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end)
    ))
end

customization.widgets.bat = awful.widget.progressbar()
customization.widgets.bat.last_perc = nil
customization.widgets.bat.warning_threshold = 10
customization.widgets.bat.instance = "BAT0"
customization.widgets.bat:set_width(8)
customization.widgets.bat:set_height(10)
customization.widgets.bat:set_vertical(true)
customization.widgets.bat:set_background_color("#494B4F")
customization.widgets.bat:set_border_color(nil)
customization.widgets.bat:set_color({
    type = "linear", from = { 0, 0 }, to = { 0, 10 },
    stops = {{ 0, "#AECF96" }, { 0.5, "#88A175" }, { 1, "#FF5656" }}
})
vicious.register(customization.widgets.bat, vicious.widgets.bat, 
    function (bat, args)
        local perc = args[2]
        -- "perc>0" checks for "no battery" (e.g., desktop computer).
        if customization.option.low_battery_notification_p and perc > 0 and perc <= bat.warning_threshold then
            if (not bat.last_perc) or (perc < bat.last_perc) then
                -- discharging
                naughty.notify({
                    preset = naughty.config.presets.critical,
                    title = "Low battery: " .. perc .. "%.",
                    text = "Please connect an AC adapter.",
                    timeout = 60
                })
            elseif perc > bat.last_perc then
                -- charging
                naughty.notify({
                    preset = naughty.config.presets.low,
                    title = "Battery is charging.",
                    text = "Current: " .. perc .. "%; warning threshold: " .. bat.warning_threshold .. "%.",
                    timeout = 5
                })
            end
            bat.last_perc = perc
        else
            bat.last_perc = nil
        end
        return perc
    end, 61, customization.widgets.bat.instance)
do
    local prog="gnome-control-center power"
    local started=false
    customization.widgets.bat:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end)
    ))
end

customization.widgets.mpdstatus = wibox.widget.textbox()
customization.widgets.mpdstatus:set_ellipsize("end")
vicious.register(customization.widgets.mpdstatus, vicious.widgets.mpd,
  function (mpdwidget, args)
    local text = nil
    local state = args["{state}"]
    if state then
      if state == "Stop" then 
        text = ""
      else 
        text = args["{Artist}"]..' - '.. args["{Title}"]
      end
      return '<span fgcolor="light green"><b>[' .. state .. ']</b> <small>' .. text .. '</small></span>'
    end
    return ""
  end, 1)
-- http://git.sysphere.org/vicious/tree/README
customization.widgets.mpdstatus = wibox.layout.constraint(customization.widgets.mpdstatus, "max", 180, nil)
do
    customization.widgets.mpdstatus:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        awful.util.spawn("mpc toggle")
    end),
    awful.button({ }, 2, function ()
        awful.util.spawn("mpc prev")
    end),
    awful.button({ }, 3, function ()
        awful.util.spawn("mpc next")
    end),
    awful.button({ }, 4, function ()
        awful.util.spawn("mpc seek -1%")
    end),
    awful.button({ }, 5, function ()
        awful.util.spawn("mpc seek +1%")
    end)
    ))
end

customization.widgets.volume = wibox.widget.textbox()
vicious.register(customization.widgets.volume, vicious.widgets.volume,
  "<span fgcolor='cyan'>$1%$2</span>", 1, "Master")
do
    local prog="pavucontrol"
    local started=false
    customization.widgets.volume:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started then
            awful.util.spawn("pkill -f '" .. prog .. "'")
        else
            awful.util.spawn(prog)
        end
        started=not started
    end),
    awful.button({ }, 2, function ()
        awful.util.spawn("amixer sset Mic toggle")
    end),
    awful.button({ }, 3, function ()
        awful.util.spawn("amixer sset Master toggle")
    end),
    awful.button({ }, 4, function ()
        awful.util.spawn("amixer sset Master 1%-")
    end),
    awful.button({ }, 5, function ()
        awful.util.spawn("amixer sset Master 1%+")
    end)
    ))
end

customization.widgets.date = wibox.widget.textbox()
vicious.register(customization.widgets.date, vicious.widgets.date, "%a %x %r %Z", 1)
do
    local prog1="gnome-control-center datetime"
    local started1=false
    local prog2="gnome-control-center region"
    local started2=false
    customization.widgets.date:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if started1 then
            awful.util.spawn("pkill -f '" .. prog1 .. "'")
        else
            awful.util.spawn(prog1)
        end
        started1=not started1
    end),
    awful.button({ }, 3, function ()
        if started2 then
            awful.util.spawn("pkill -f '" .. prog2 .. "'")
        else
            awful.util.spawn(prog2)
        end
        started2=not started2
    end)
    ))
end

-- Create a wibox for each screen and add it

customization.widgets.uniarg = {}
customization.widgets.wibox = {}
customization.widgets.promptbox = {}
customization.widgets.layoutbox = {}
customization.widgets.taglist = {}
customization.widgets.taglist.buttons = awful.util.table.join(
awful.button({ }, 1, awful.tag.viewonly),
awful.button({ modkey }, 1, awful.client.movetotag),
awful.button({ }, 2, awful.tag.viewtoggle),
awful.button({ modkey }, 2, awful.client.toggletag),
awful.button({ }, 3, function (t)
  customization.func.tag_action_menu(t)
end),
awful.button({ modkey }, 3, awful.tag.delete),
awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
)

customization.widgets.tasklist = {}
customization.widgets.tasklist.buttons = awful.util.table.join(

awful.button({ }, 1, function (c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end),

awful.button({ }, 2, function (c)
  customization.func.clients_on_tag()
end),

awful.button({ modkey }, 2, function (c)
    customization.func.all_clients()
end),

awful.button({ }, 3, function (c)
  customization.func.client_action_menu(c)
end),

awful.button({ }, 4, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end),

awful.button({ }, 5, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end))

-- start bashets
bashets.start()

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local prev_scr_count = nil
awful.screen.connect_for_each_screen(
function(s)
    -- Wallpaper
    set_wallpaper(s)
    -- Set a default tag is there is none.
    timer.delayed_call(function () 
        local si = s.index
        if #s.tags < 1 then
            local tag = awful.tag.add("main" .. si,
            {
                screen = si,
                layout = customization.default.property.layout,
                mwfact = customization.default.property.mwfact,
                nmaster = customization.default.property.nmaster,
                ncol = customization.default.property.ncol, 
            } 
            )
            awful.tag.viewonly(tag)
        end
    end)
    -- Create a promptbox for each screen
    customization.widgets.promptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    customization.widgets.layoutbox[s] = awful.widget.layoutbox(s)
    customization.widgets.layoutbox[s]:buttons(awful.util.table.join(
        awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
        awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function () awful.layout.inc(layouts, -1) end),
        awful.button({ }, 5, function () awful.layout.inc(layouts, 1) end),
        nil
    ))
    -- Create a taglist widget
    customization.widgets.taglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, customization.widgets.taglist.buttons)

    -- Create a textbox showing current universal argument
    customization.widgets.uniarg[s] = wibox.widget.textbox()
    -- Create a tasklist widget
    customization.widgets.tasklist[s] = awful.widget.tasklist(
        s, awful.widget.tasklist.filter.currenttags, customization.widgets.tasklist.buttons
        )

    -- Create the wibox
    customization.widgets.wibox[s] = awful.wibox({ position = "top", screen = s })

    customization.widgets.wibox[s]:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            customization.widgets.launcher,
            customization.widgets.taglist[s],
            customization.widgets.uniarg[s],
            customization.widgets.promptbox[s],
        },
        customization.widgets.tasklist[s], -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            customization.widgets.keyboardlayout,
            wibox.widget.systray(),
            customization.widgets.cpuusage,
            customization.widgets.memusage,
            customization.widgets.bat,
            customization.widgets.mpdstatus,
            customization.widgets.volume,
            customization.widgets.date,
            customization.widgets.layoutbox[s],
        },
    }

end
)

util.taglist.set_taglist(customization.widgets.taglist)
-- }}}

do
    -- test whether screen 1 tag file exists
    local f = io.open(awesome_tags_fname .. ".0", "r")
    if f then
        local old_scr_count = tonumber(f:read("*l"))
        f:close()
        os.remove(awesome_tags_fname .. ".0")

        local new_scr_count = screen.count()

        local count = {}

        local scr_count = math.min(new_scr_count, old_scr_count)

        if scr_count>0 then
            for s = 1, scr_count do
                count[s] = 1
            end

            for s = 1, old_scr_count do
                local count_index = math.min(s, scr_count)
                local fname = awesome_tags_fname .. "." .. s
                local f = io.open(fname, "r")
                if f then 
                    f:close()
                    for tagname in io.lines(fname) do
                        local tag = awful.tag.add(tagname,
                        {
                            screen = count_index,
                            layout = customization.default.property.layout,
                            mwfact = customization.default.property.mwfact,
                            nmaster = customization.default.property.nmaster,
                            ncol = customization.default.property.ncol,
                        }
                        )
                        awful.tag.move(count[count_index], tag)
                        count[count_index] = count[count_index]+1
                    end
                end
                os.remove(fname)
            end
        end

        for s = 1, screen.count() do
            local tags = awful.tag.gettags(s)
            if #tags >= 1 then
                local fname = awesome_tags_fname .. "-selected." .. s 
                f = io.open(fname, "r")
                if f then
                    local tag = awful.tag.gettags(s)[tonumber(f:read("*l"))]
                    if tag then
                        awful.tag.viewonly(tag)
                    end
                    f:close()
                end
                os.remove(fname)
            else
                local tag = awful.tag.add("main" .. s,
                {
                    screen = s,
                    layout = customization.default.property.layout,
                    mwfact = customization.default.property.mwfact,
                    nmaster = customization.default.property.nmaster,
                    ncol = customization.default.property.ncol, 
                } 
                )
                awful.tag.viewonly(tag)
            end
        end

    else

        for s = 1, screen.count() do
            local tags = awful.tag.gettags(s)
            if #tags < 1 then
                local tag = awful.tag.add("main" .. s,
                {
                    screen = s,
                    layout = customization.default.property.layout,
                    mwfact = customization.default.property.mwfact,
                    nmaster = customization.default.property.nmaster,
                    ncol = customization.default.property.ncol, 
                } 
                )
                awful.tag.viewonly(tag)
            end
        end

    end
end


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
awful.button({ }, 1, customization.func.all_clients),
awful.button({ }, 2, customization.func.tag_action_menu),
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewprev),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
notifylist = {}
-- {{{ Key bindings

local globalkeys = nil
local clientkeys = nil

uniarg:init(customization.widgets.uniarg)

globalkeys = awful.util.table.join(

-- universal arguments

awful.key({ modkey }, "u",
function ()
    uniarg:activate()
    awful.prompt.run({prompt = "Universal Argument: ", text='' .. uniarg.arg, selectall=true},
    customization.widgets.promptbox[awful.screen.focused()].widget,
    function (t)
        uniarg.persistent = false
        local n = t:match("%d+")
        if n then
            uniarg:set(n)
            uniarg:update_textbox()
            if uniarg.arg>1 then
                return
            end
        end
        uniarg:deactivate()
    end)
end),

-- persistent universal arguments
awful.key({ modkey, "Shift" }, "u",
function ()
    uniarg:activate()
    awful.prompt.run({prompt = "Persistent Universal Argument: ", text='' .. uniarg.arg, selectall=true},
    customization.widgets.promptbox[awful.screen.focused()].widget,
    function (t)
        uniarg.persistent = true
        local n = t:match("%d+")
        if n then
            uniarg:set(n)
        end
        uniarg:update_textbox()
    end)
end),

-- window management

--- restart/quit/info

awful.key({ modkey, "Control" }, "r", awesome.restart),

awful.key({ modkey, "Control", "Shift" }, "r", customization.orig.restart),

awful.key({ modkey, "Shift"   }, "q", awesome.quit),

awful.key({ modkey, "Shift", "Control" }, "q", customization.orig.quit),

awful.key({ modkey }, "\\", customization.func.systeminfo),

awful.key({ modkey }, "F1", customization.func.help),

awful.key({ modkey, "Shift" }, "F1", hotkeys_popup.show_help),

awful.key({ "Ctrl", "Shift" }, "Escape", function ()
    awful.util.spawn(tools.system.taskmanager)
end),

--- Layout

uniarg:key_repeat({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),

uniarg:key_repeat({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

--- multiple screens/multi-head/RANDR

uniarg:key_repeat({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),

uniarg:key_repeat({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),

uniarg:key_repeat({ modkey,           }, "o", awful.client.movetoscreen),

uniarg:key_repeat({ modkey, "Control" }, "o", customization.func.tag_move_screen_next),

uniarg:key_repeat({ modkey, "Shift", "Control" }, "o", customization.func.tag_move_screen_prev),

uniarg:key_repeat({ modkey, "Shift", "Control" }, "\\", xrandr.xrandr),

uniarg:key_repeat({ modkey, "Mod1", "Control" }, "\\", foggy.menu),

--- misc

awful.key({modkey}, "F2", function()
    awful.prompt.run(
    {prompt = "Run: "},
    customization.widgets.promptbox[awful.screen.focused()].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),

awful.key({modkey}, "r", function()
    awful.prompt.run(
    {prompt = "Run: "},
    customization.widgets.promptbox[awful.screen.focused()].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),

awful.key({modkey}, "F3", function()
    local config_path = awful.util.getdir("config")
    awful.util.spawn_with_shell(config_path .. "/bin/trackpad-toggle.sh")
end),

awful.key({modkey}, "F4", function()
    awful.prompt.run(
    {prompt = "Run Lua code: "},
    customization.widgets.promptbox[awful.screen.focused()].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval"
    )
end),

awful.key({ modkey }, "c", function () 
    awful.util.spawn(tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

awful.key({ modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, ";", function()
  local c = client.focus
  if c then
    customization.func.client_action_menu(c)
  end
end),

awful.key({ modkey, "Shift" }, ";", customization.func.tag_action_menu),

awful.key({ modkey, }, "'", customization.func.clients_on_tag),

awful.key({ modkey, "Ctrl" }, "'", customization.func.clients_on_tag_prompt),

awful.key({ modkey, "Shift" }, "'", customization.func.all_clients),

awful.key({ modkey, "Shift", "Ctrl" }, "'", customization.func.all_clients_prompt),

awful.key({ modkey, }, "x", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, "X", function() mymainmenu:toggle({keygrabber=true}) end),

uniarg:key_repeat({ modkey,           }, "Return", function () awful.util.spawn(tools.terminal) end),

uniarg:key_repeat({ modkey, "Mod1" }, "Return", function () awful.util.spawn("gksudo " .. tools.terminal) end),

-- dynamic tagging

awful.key({ modkey, "Ctrl", "Mod1" }, "t", function () 
  customization.option.tag_persistent_p = not customization.option.tag_persistent_p
  local msg = nil
  if customization.option.tag_persistent_p then
    msg = "Tags will persist across exit/restart."
  else
    msg = "Tags will <span fgcolor='red'>NOT</span> persist across exit/restart."
  end
  naughty.notify({
    preset = naughty.config.presets.normal,
    title="Tag persistence",
    text=msg,
    timeout = 1,
    screen = awful.screen.focused(),
    })
end),

--- add/delete/rename

awful.key({modkey}, "a", customization.func.tag_add_after),

awful.key({modkey, "Shift"}, "a", customization.func.tag_add_before),

awful.key({modkey, "Shift"}, "d", customization.func.tag_delete),

awful.key({modkey, "Shift"}, "r", customization.func.tag_rename),

--- view

uniarg:key_repeat({modkey,}, "p", customization.func.tag_view_prev),

uniarg:key_repeat({modkey,}, "n", customization.func.tag_view_next),

awful.key({modkey,}, "z", customization.func.tag_last),

awful.key({modkey,}, "g", customization.func.tag_goto),

--- move

uniarg:key_repeat({modkey, "Control"}, "p", customization.func.tag_move_backward), 

uniarg:key_repeat({modkey, "Control"}, "n", customization.func.tag_move_forward), 

-- client management

--- change focus

uniarg:key_repeat({ modkey,           }, "j", customization.func.client_focus_next),

uniarg:key_repeat({ modkey,           }, "Tab", customization.func.client_focus_next),

uniarg:key_repeat({ modkey,           }, "k", customization.func.client_focus_prev),

uniarg:key_repeat({ modkey, "Shift"   }, "Tab", customization.func.client_focus_prev),

awful.key({ modkey,           }, "y", customization.func.client_focus_urgent),

--- swap order/select master

uniarg:key_repeat({ modkey, "Shift"   }, "j", customization.func.client_swap_next),

uniarg:key_repeat({ modkey, "Shift"   }, "k", customization.func.client_swap_prev),

--- move/copy to tag

uniarg:key_repeat({modkey, "Shift"}, "n", customization.func.client_move_next),

uniarg:key_repeat({modkey, "Shift"}, "p", customization.func.client_move_prev),

awful.key({modkey, "Shift"}, "g", customization.func.client_move_to_tag),

awful.key({modkey, "Control", "Shift"}, "g", customization.func.client_toggle_tag),

--- change space allocation in tile layout

awful.key({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05) end),

awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05) end),

uniarg:key_repeat({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster( 1) end),

uniarg:key_repeat({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster(-1) end),

uniarg:key_repeat({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1) end),

uniarg:key_repeat({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1) end),

--- misc

awful.key({ modkey, "Shift" }, "`", customization.func.client_toggle_titlebar),

-- app bindings

--- admin

awful.key({ modkey, }, "`", customization.func.system_lock),

awful.key({ modkey, }, "Home", customization.func.system_lock),

awful.key({ modkey, }, "End", customization.func.system_suspend),

awful.key({ modkey,  "Mod1" }, "Home", customization.func.system_hibernate),

awful.key({ modkey,  "Mod1" }, "End", customization.func.system_hybrid_sleep),

awful.key({ modkey, }, "Insert", customization.func.system_reboot),

awful.key({ modkey, }, "Delete", customization.func.system_power_off),

awful.key({ modkey, }, "/", customization.func.app_finder),

--- everyday

uniarg:key_repeat({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(tools.system.filemanager)
end),

uniarg:key_repeat({ modkey,  }, "e", function ()
    awful.util.spawn(tools.system.filemanager)
end),

uniarg:key_repeat({ modkey,  }, "E", function ()
    awful.util.spawn(tools.system.filemanager)
end),

uniarg:key_repeat({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
end),

uniarg:key_repeat({ modkey, "Mod1", }, "r", function ()
    awful.util.spawn("remmina")
end),

uniarg:key_repeat({ modkey, }, "i", function ()
    awful.util.spawn(tools.editor.primary)
end),

uniarg:key_repeat({ modkey, "Shift" }, "i", function ()
    awful.util.spawn(tools.editor.secondary)
end),

uniarg:key_repeat({ modkey, "Shift", "Ctrl" }, "i", function ()
    awful.util.spawn("emacs")
end),

uniarg:key_repeat({ modkey, }, "b", function ()
    awful.util.spawn(tools.browser.primary)
end),

uniarg:key_repeat({ modkey, "Shift" }, "b", function ()
    awful.util.spawn(tools.browser.secondary)
end),

uniarg:key_repeat({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("virtualbox")
end),

uniarg:key_repeat({ modkey, "Mod1", }, "z", function ()
    awful.util.spawn("zeal")
end),

uniarg:key_repeat({modkey, "Shift" }, "\\", function() 
    awful.util.spawn("kmag")
end),

uniarg:key_repeat({modkey, "Mod1" }, ";", function() 
    awful.util.spawn("hotrecoll.py")
end),

-- Negate/invert screen color.
awful.key({modkey, "Mod1", "Shift", "Control" }, "n", function() 
    awful.util.spawn("xcalib -i -a -s " .. ((screen[mouse.screen].index-1)))
end),

awful.key({modkey, "Mod1", "Shift", "Control" }, "N", function() 
    awful.util.spawn("xcalib -i -a -s " .. ((screen[mouse.screen].index-1)))
end),

--- the rest

uniarg:key_repeat({}, "XF86AudioPrev", function ()
    awful.util.spawn("mpc prev")
end),

uniarg:key_repeat({}, "XF86AudioNext", function ()
    awful.util.spawn("mpc next")
end),

awful.key({}, "XF86AudioPlay", function ()
    awful.util.spawn("mpc toggle")
end),

awful.key({}, "XF86AudioStop", function ()
    awful.util.spawn("mpc stop")
end),

uniarg:key_numarg({}, "XF86AudioRaiseVolume",
function ()
  awful.util.spawn("amixer sset Master 5%+")
end,
function (n)
  awful.util.spawn("amixer sset Master " .. n .. "%+")
end),

uniarg:key_numarg({}, "XF86AudioLowerVolume",
function ()
  awful.util.spawn("amixer sset Master 5%-")
end,
function (n)
  awful.util.spawn("amixer sset Master " .. n .. "%-")
end),

awful.key({}, "XF86AudioMute", function ()
    awful.util.spawn("amixer sset Master toggle")
end),

awful.key({}, "XF86AudioMicMute", function ()
    awful.util.spawn("amixer sset Mic toggle")
end),

awful.key({}, "XF86ScreenSaver", function ()
    awful.util.spawn("xscreensaver-command -l")
end),

awful.key({}, "XF86WebCam", function ()
    awful.util.spawn("cheese")
end),

uniarg:key_numarg({}, "XF86MonBrightnessUp",
function ()
  awful.util.spawn("xbacklight -inc 10")
end,
function (n)
  awful.util.spawn("xbacklight -inc " .. n)
end),

uniarg:key_numarg({}, "XF86MonBrightnessDown",
function ()
  awful.util.spawn("xbacklight -dec 10")
end,
function (n)
  awful.util.spawn("xbacklight -dec " .. n)
end),

awful.key({}, "XF86WLAN", function ()
    awful.util.spawn("nm-connection-editor")
end),

awful.key({}, "XF86Display", function ()
    awful.util.spawn("arandr")
end),

awful.key({}, "Print", function ()
    awful.util.spawn("xfce4-screenshooter")
end),

uniarg:key_repeat({}, "XF86Launch1", function ()
    awful.util.spawn(tools.terminal)
end),

awful.key({ }, "XF86Sleep", function ()
    awful.util.spawn("systemctl suspend")
end),


awful.key({ modkey }, "XF86Sleep", function ()
    awful.util.spawn("systemctl hibernate")
end),

--- hacks for Thinkpad W530 FN mal-function

uniarg:key_repeat({ modkey }, "F10", function ()
    awful.util.spawn("mpc prev")
end),

awful.key({ modkey }, "F11", function ()
    awful.util.spawn("mpc toggle")
end),

uniarg:key_repeat({ modkey }, "F12", function ()
    awful.util.spawn("mpc next")
end),

uniarg:key_repeat({ modkey, "Control" }, "Left", function ()
    awful.util.spawn("mpc prev")
end),

awful.key({ modkey, "Control" }, "Down", function ()
    awful.util.spawn("mpc toggle")
end),

uniarg:key_repeat({ modkey, "Control" }, "Right", function ()
    awful.util.spawn("mpc next")
end),

awful.key({ modkey, "Control" }, "Up", function ()
    awful.util.spawn("pavucontrol")
end),

uniarg:key_numarg({ modkey, "Shift" }, "Left",
function ()
  awful.util.spawn("mpc seek -1%")
end,
function (n)
  awful.util.spawn("mpc seek -" .. n .. "%")
end),

uniarg:key_numarg({ modkey, "Shift" }, "Right",
function ()
  awful.util.spawn("mpc seek +1%")
end,
function (n)
  awful.util.spawn("mpc seek +" .. n .. "%")
end),

uniarg:key_numarg({ modkey, "Shift" }, "Down",
function ()
  awful.util.spawn("mpc seek -10%")
end,
function (n)
  awful.util.spawn("mpc seek -" .. n .. "%")
end),

uniarg:key_numarg({ modkey, "Shift" }, "Up",
function ()
  awful.util.spawn("mpc seek +10%")
end,
function (n)
  awful.util.spawn("mpc seek +" .. n .. "%")
end),

nil

)

-- client management

--- operation
clientkeys = awful.util.table.join(

awful.key({ modkey, "Shift"   }, "c", customization.func.client_kill),

awful.key({ "Mod1",   }, "F4", customization.func.client_kill),

awful.key({ modkey,           }, "f", customization.func.client_fullscreen),

awful.key({ modkey,           }, "m", customization.func.client_maximize),

-- move client to sides, i.e., sidelining

awful.key({ modkey,           }, "Left", customization.func.client_sideline_left),

awful.key({ modkey,           }, "Right", customization.func.client_sideline_right),

awful.key({ modkey,           }, "Up", customization.func.client_sideline_top),

awful.key({ modkey,           }, "Down", customization.func.client_sideline_bottom),

-- extend client sides

uniarg:key_numarg({ modkey, "Mod1"    }, "Left",
customization.func.client_sideline_extend_left,
function (n, c)
customization.func.client_sideline_extend_left(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Right",
customization.func.client_sideline_extend_right,
function (n, c)
customization.func.client_sideline_extend_right(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Up",
customization.func.client_sideline_extend_top,
function (n, c)
customization.func.client_sideline_extend_top(c, n)
end),

uniarg:key_numarg({ modkey, "Mod1"    }, "Down",
customization.func.client_sideline_extend_bottom,
function (n, c)
customization.func.client_sideline_extend_bottom(c, n)
end),

-- shrink client sides

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Left",
customization.func.client_sideline_shrink_left,
function (n, c)
customization.func.client_sideline_shrink_left(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Right",
customization.func.client_sideline_shrink_right,
function (n, c)
customization.func.client_sideline_shrink_right(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Up",
customization.func.client_sideline_shrink_top,
function (n, c)
customization.func.client_sideline_shrink_top(c, n)
end
),

uniarg:key_numarg({ modkey, "Mod1", "Shift" }, "Down",
customization.func.client_sideline_shrink_bottom,
function (n, c)
customization.func.client_sideline_shrink_bottom(c, n)
end
),

-- maximize/minimize

awful.key({ modkey, "Shift"   }, "m", customization.func.client_minimize),

awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),


awful.key({ modkey,           }, "t", customization.func.client_toggle_top),

awful.key({ modkey,           }, "s", customization.func.client_toggle_sticky),

awful.key({ modkey,           }, ",", customization.func.client_maximize_horizontal),

awful.key({ modkey,           }, ".", customization.func.client_maximize_vertical),

awful.key({ modkey,           }, "[", customization.func.client_opaque_less),

awful.key({ modkey,           }, "]", customization.func.client_opaque_more),

awful.key({ modkey, 'Shift'   }, "[", customization.func.client_opaque_off),

awful.key({ modkey, 'Shift'   }, "]", customization.func.client_opaque_on),

awful.key({ modkey, "Control" }, "Return", customization.func.client_swap_with_master),

nil

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9, plus 0.

for i = 1, 10 do
    local keycode = "#" .. i+9

    globalkeys = awful.util.table.join(globalkeys,

    awful.key({ modkey }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(awful.screen.focused())
        if i <= #tags then
            tag = tags[i]
        else
            local scr = awful.screen.focused()
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            customization.widgets.promptbox[scr].widget,
            function (text)
                if #text>0 then
                    tag = awful.tag.add(text)
                    awful.tag.setscreen(tag, scr)
                    awful.tag.move(#tags+1, tag)
                    awful.tag.viewonly(tag)
                end
            end,
            nil)
        end
        if tag then
            awful.tag.viewonly(tag)
        end
    end),

    awful.key({ modkey, "Control" }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(awful.screen.focused())
        if i <= #tags then
            tag = tags[i]
        else
            local scr = awful.screen.focused()
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            customization.widgets.promptbox[scr].widget,
            function (text)
                if #text>0 then
                    tag = awful.tag.add(text)
                    awful.tag.setscreen(tag, scr)
                    awful.tag.move(#tags+1, tag)
                    awful.tag.viewonly(tag)
                end
            end,
            nil)
        end
        if tag then
            awful.tag.viewtoggle(tag)
        end
    end),

    awful.key({ modkey, "Shift" }, keycode,
    function ()
        local focus = client.focus

        if focus then
            local tag
            local tags = awful.tag.gettags(focus.screen)
            if i <= #tags then
                tag = tags[i]
            else
                local scr = awful.screen.focused()
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                customization.widgets.promptbox[scr].widget,
                function (text)
                    if #text>0 then
                        tag = awful.tag.add(text)
                        awful.tag.setscreen(tag, scr)
                        awful.tag.move(#tags+1, tag)
                        awful.tag.viewonly(tag)
                    end
                end,
                nil)
            end
            if tag then
                awful.client.movetotag(tag)
            end
        end
    end),

    awful.key({ modkey, "Control", "Shift" }, keycode,
    function ()
        local focus = client.focus

        if focus then
            local tag
            local tags = awful.tag.gettags(client.focus.screen)
            if i <= #tags then
                tag = tags[i]
            else
                local scr = awful.screen.focused()
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                customization.widgets.promptbox[scr].widget,
                function (text)
                    if #text>0 then
                        tag = awful.tag.add(text)
                        awful.tag.setscreen(tag, scr)
                        awful.tag.move(#tags+1, tag)
                        awful.tag.viewonly(tag)
                    end
                end,
                nil)
            end
            if tag then
                awful.client.toggletag(tag)
            end
        end
    end),

    nil
    )
end

clientbuttons = awful.util.table.join(
awful.button({ }, 1, function (c)
  if awful.client.focus.filter(c) then
    client.focus = c
    c:raise()
  end
end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {

    -- All clients will match this rule.
    { 
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            opacity = customization.default.property.default_naughty_opacity,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
        }
    },

    { 
        rule = { class = "MPlayer" },
        properties = { 
            floating = true,
            opacity = 1,
        } 
    },

    { 
        rule = { class = "gimp" },
        properties = { 
            floating = true, 
        }, 
    },

    --[[
    Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][2] } },
    --]]

    {
        rule = { class = "Kmag" },
        properties = {
            ontop = true,
            floating = true,
            opacity = 0.8,
            sticky = true,
        },
        callback = function (c)
        end,
    },


    {
        rule = { class = "Conky" },
        properties = {
            sticky = true,
            opacity = 0.4,
            focusable = false,
            ontop = false,
        },
    }

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = true
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then

        -- buttons for the titlebar
        local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
        )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)

        -- hide the titlebar by default (it takes space)
        awful.titlebar.hide(c)

    end

end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

customization.func.client_manage_tag = function (c, startup)
    if startup then
        local client_id = c.pid .. '-' .. c.window

        local fname = awesome_client_tags_fname .. '/' .. client_id
        local f = io.open(fname, 'r')

        if f then
            local tags = {}
            for tag in io.lines(fname) do
                tags = awful.util.table.join(tags, {util.tag.name2tag(tag)})
            end
            -- remove the file after using it to reduce clutter
            os.remove(fname)

            if #tags>0 then
                c:tags(tags)
                -- set c's screen to that of its first (often the only) tag
                -- this prevents client to be placed off screen in case of randr change (on the number of screen)
                c.screen = awful.tag.getscreen(tags[1])
                awful.placement.no_overlap(c)
                awful.placement.no_offscreen(c)
            end
        end
    end
end

client.connect_signal("manage", customization.func.client_manage_tag)

-- }}}

-- disable startup-notification globally
-- prevent unintended mouse cursor change
customization.orig.awful_util_spawn = awful.util.spawn
awful.util.spawn = function (s)
    customization.orig.awful_util_spawn(s, false)
end

-- XDG style autostart with "dex"
-- HACK continue
awful.util.spawn_with_shell("if ! [ -e " .. awesome_autostart_once_fname .. " ]; then dex -a -e awesome; touch " .. awesome_autostart_once_fname .. "; fi")
--customization.func.client_opaque_on(nil) -- start xcompmgr
