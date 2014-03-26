-- default rc.lua for shifty
--
-- Standard awesome library
-- to find local libraries
package.path = package.path .. ";./?/init.lua;"

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
require("awful.dbus")
require("awful.remote")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")

-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("bashets")

awesome.orig = {}

do
    local config_path = awful.util.getdir("config")
    bashets.set_script_path(config_path .. "/bashets/")
end

local shifty = require("shifty")
shifty.config.defaults.rel_index = 1
shifty.config.remember_index = false
shifty.config.guess_position = false

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
-- * create a file /tmp/awesome-autostart-once when first time "dex" autostart items (at the end of this file)
-- * only "rm" this file when awesome.quit

local awesome_autostart_once_fname = "/tmp/awesome-autostart-once-" .. os.getenv("XDG_SESSION_ID")
local awesome_restart_tags_fname = "/tmp/awesome-restart-tags-" .. os.getenv("XDG_SESSION_ID")

do
    awesome.connect_signal("exit", function (restart)
        if not restart then
            awful.util.spawn_with_shell("rm -rf " .. awesome_autostart_once_fname)
            awful.util.spawn_with_shell("rm -rf " .. awesome_restart_tags_fname .. '*')
            bashets.stop()
        end
    end)

    awesome.orig.quit = awesome.quit
    awesome.quit = function ()
        local scr = mouse.screen
        awful.prompt.run({prompt = "Quit (type 'yes' to confirm)? "},
        mypromptbox[scr].widget,
        function (t)
            if string.lower(t) == 'yes' then
                awesome.orig.quit()
            end
        end,
        function (t, p, n)
            return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
        end,
        nil)
    end
end

do

    awesome.connect_signal("exit", function (restart)
        if restart then
            -- save number of screens, used for check proper tag recording
            do
                local f = io.open(awesome_restart_tags_fname .. ".0", "w+")
                if f then
                    f:write(string.format("%d", screen.count()) .. "\n")
                    f:close()
                end
            end

            -- save current tags
            for s = 1, screen.count() do
                local f = io.open(awesome_restart_tags_fname .. "." .. s, "w+")
                if f then
                    local tags = awful.tag.gettags(s)
                    for _, tag in ipairs(tags) do
                        f:write(tag.name .. "\n")
                    end
                    f:close()
                end
                f = io.open(awesome_restart_tags_fname .. "-selected." .. s, "w+")
                if f then
                    f:write(awful.tag.selected(s).name .. "\n")
                    f:close()
                end
            end

            -- save tags for each client
            awful.util.mkdir(awesome_restart_tags_fname)
            -- !! avoid awful.util.spawn_with_shell("mkdir -p " .. awesome_restart_tags_fname) 
            -- race condition (whether awesome_restart_tags_fname is created) due to asynchrony of "spawn_with_shell"
            for _, c in ipairs(client.get()) do
                local f = io.open(awesome_restart_tags_fname .. '/' .. c.pid, 'w+')
                if f then
                    for _, t in ipairs(c:tags()) do
                        f:write(t.name .. "\n")
                    end
                    f:close()
                end
            end
        end
    end)

    awesome.orig.restart = awesome.restart
    awesome.restart = function ()
        local scr = mouse.screen
        awful.prompt.run({prompt = "Restart (type 'yes' to confirm)? "},
        mypromptbox[scr].widget,
        function (t)
            if string.lower(t) == 'yes' then
                awesome.orig.restart()
            end
        end,
        function (t, p, n)
            return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
        end,
        nil)
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

    -- random wallpaper from a gallery
    local wallpaper_freq="30s"

    awful.util.spawn_with_shell("( cd ".. config_path .. "/wallpaper; " ..
    "if ! killall -q my-wallpaper-pick.sh; then " ..
    "  ./my-wallpaper-pick.sh " .. wallpaper_freq .."; " ..
    "fi  ) &")
end
--]]
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.

--{{
local tools = {
    -- sakura does not interfere with readline function with menu
    terminal = "sakura",
    system = {
        filemanager = "thunar",
    },
    browser = {
    },
    editor = {
    },
}

tools.browser.primary = os.getenv("BROWSER") or "chromium"
tools.browser.secondary = ({chromium="firefox", firefox="chromium"})[tools.browser.primary]
tools.editor.primary = os.getenv("EDITOR") or "gvim"
tools.editor.secondary = ({emacs="gvim", gvim="emacs"})[tools.editor.primary]

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
                table.insert(current, {k, v})
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
layouts =
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

-- SHIFTY: application matching rules
-- order here matters, early rules will be applied first
shifty.config.apps = {
    {
        match = {""},
        buttons = awful.util.table.join(
        awful.button({}, 1, function (c) client.focus = c; c:raise() end),
        awful.button({modkey}, 1, function(c)
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({modkey}, 3, awful.mouse.client.resize)
        )
    },
}

-- SHIFTY: default tag creation rules
-- parameter description
--  * floatBars : if floating clients should always have a titlebar
--  * guess_name : should shifty try and guess tag names when creating
--                 new (unconfigured) tags?
--  * guess_position: as above, but for position parameter
--  * run : function to exec when shifty creates a new tag
--  * all other parameters (e.g. layout, mwfact) follow awesome's tag API
shifty.config.defaults = {
    --layout = awful.layout.suit.tile.bottom,
    layout = awful.layout.suit.floating,
    ncol = 1,
    mwfact = 0.50,
    floatBars = true,
    guess_name = true,
    guess_position = true,
}



-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    --{ "manual", tools.terminal .. " -e man awesome" },
    { "edit config", tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
    { "restart", awesome.restart },
    { "quit", awesome.quit }
}

mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "applications", myapp },
        { "open terminal", tools.terminal },
    }
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = tools.terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
-- mytextclock = awful.widget.textclock()
mytextclock = wibox.widget.textbox()

-- http://awesome.naquadah.org/wiki/Bashets
bashets.register("date.sh", {widget=mytextclock, update_time=1, format="<small>$1</small> <span fgcolor='red'>$3 $2 $6</span> <b>$4 $5</b>"})

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
awful.button({ }, 1, awful.tag.viewonly),
awful.button({ modkey }, 1, awful.client.movetotag),
awful.button({ }, 3, awful.tag.viewtoggle),
awful.button({ modkey }, 3, awful.client.toggletag),
awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)

mytasklist = {}
mytasklist.buttons = awful.util.table.join(
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
awful.button({ }, 3, function ()
    if instance then
        instance:hide()
        instance = nil
    else
        instance = awful.menu.clients({ width=250 })
    end
end),
awful.button({ }, 4, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end),
awful.button({ }, 5, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end))

-- start bashets
bashets.start()

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- SHIFTY: initialize shifty
-- the assignment of shifty.taglist must always be after its actually
-- initialized with awful.widget.taglist.new()
shifty.taglist = mytaglist

do
    -- test whether screen 1 tag file exists
    local f = io.open(awesome_restart_tags_fname .. ".0", "r")
    if f then
        local old_scr_count = tonumber(f:read("*l"))
        f:close()
        awful.util.spawn_with_shell("rm -rf " .. awesome_restart_tags_fname .. ".0")

        local new_scr_count = screen.count()

        local count = {}

        local scr_count = math.min(new_scr_count, old_scr_count)

        if scr_count>0 then
            for s = 1, scr_count do
                count[s] = 1
            end

            shifty.config.tags = {}
            for s = 1, old_scr_count do
                local count_index = math.min(s, scr_count)
                for tagname in io.lines(awesome_restart_tags_fname .. "." .. s) do
                    shifty.config.tags = awful.util.table.join(shifty.config.tags,
                    {
                        [tagname] = {
                            screen = math.min(new_scr_count, s),
                            position = count[count_index],
                            layout = shifty.config.defaults.layout, 
                            mwfact = shifty.config.defaults.mwfact,
                            init = true,
                        }
                    }
                    )
                    count[count_index] = count[count_index]+1
                end
            end
        end
        -- create the tags
        shifty.init()

        for s = 1, screen.count() do
            f = io.open(awesome_restart_tags_fname .. "-selected." .. s, "r")
            if f then
                local tag = f:read("*l")
                if tag then
                    awful.tag.viewonly(name2tag(tag))
                end
                f:close()
            end
        end

    else
        shifty.config.tags = {
            ["genesis"] = {
                layout    = awful.layout.suit.floating,
                mwfact    = 0.50,
                exclusive = false,
                position  = 0,
                init      = true,
                screen    = 1,
                slave     = true,
            },
            ["nil"] = {
                layout    = awful.layout.suit.floating,
                mwfact    = 0.50,
                exclusive = false,
                position  = 0,
                init      = true,
                screen    = 2,
                slave     = true,
            },
        }

        -- create the tags
        shifty.init()
    end
end


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewnext),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

-- Shifty: keybindings specific to shifty
--[[
awful.key({modkey, "Shift"}, "d", shifty.del), -- delete a tag
awful.key({modkey, "Shift"}, "n", shifty.send_prev), -- client to prev tag
awful.key({modkey}, "n", shifty.send_next), -- client to next tag
awful.key({modkey, "Control"},
"n",
function()
local t = awful.tag.selected()
local s = awful.util.cycle(screen.count(), awful.tag.getscreen(t) + 1)
awful.tag.history.restore()
t = shifty.tagtoscr(s, t)
awful.tag.viewonly(t)
end),
--]]
awful.key({modkey, "Shift"}, "d", function ()
    local tag = awful.tag.selected(mouse.screen)
    if tag then
        shifty.del(tag)
    end
end
),

awful.key({modkey, "Shift"}, "p", function ()
    local c = client.focus
    if c then
        shifty.send_prev()
    end
end),
awful.key({modkey, "Shift"}, "n", function ()
    local c = client.focus
    if c then
        shifty.send_next()
    end
end),
awful.key({modkey, "Control"}, "p", shifty.shift_prev), -- shift tag left
awful.key({modkey, "Control"}, "n", shifty.shift_next), -- shift tag right
awful.key({modkey,}, "p", awful.tag.viewprev),
awful.key({modkey,}, "n", awful.tag.viewnext),

awful.key({modkey}, "a", function ()
    local newindex = awful.tag.getidx() and (awful.tag.getidx() + 1) or 1
    shifty.add({index = newindex})
end), -- create a new tag
awful.key({modkey, "Shift"}, "r", shifty.rename), -- rename a tag
awful.key({modkey, "Shift"}, "a", -- nopopup new tag
function()
    local newindex = awful.tag.getidx() and (awful.tag.getidx() + 1) or 1
    shifty.add({nopopup = true, index = newindex})
end),

awful.key({modkey,}, "g",  -- find a tag and view it
function () 
    local keywords = {}
    local scr = mouse.screen
    for i, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Find tag: "},
    mypromptbox[scr].widget,
    function (t)
        awful.tag.viewonly(name2tag(t))
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end),
awful.key({modkey, "Shift"}, "g",  -- find a tag and move the client to it
function () 
    local keywords = {}
    local scr = mouse.screen
    for i, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Move client to tag: "},
    mypromptbox[scr].widget,
    function (t)
        awful.client.movetotag(name2tag(t))
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end,
    nil)
end),

awful.key({ modkey,           }, "j",
function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end),
awful.key({ modkey,           }, "k",
function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end),

-- get main menu
--awful.key({ modkey,           }, "/", function () mymainmenu:show() end),
--awful.key({ modkey,  "Shift"  }, "/", function () mymainmenu:show() end),
awful.key({modkey,}, "/", function() mymainmenu:toggle({keygrabber=true}) end),
awful.key({modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

-- Layout manipulation
awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
awful.key({ modkey,           }, "Tab",
function ()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end),

-- Standard program
awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
awful.key({ modkey, "Control" }, "r", awesome.restart),
awful.key({ modkey, "Shift"   }, "q", awesome.quit),

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
awful.key({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

--~ awful.key({ modkey, "Control" }, "n", awful.client.restore),

-- Prompt
awful.key({modkey}, "F1", function()
    awful.prompt.run(
    {prompt = "Run: "},
    mypromptbox[mouse.screen].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),

awful.key({modkey}, "F4", function()
    awful.prompt.run(
    {prompt = "Run Lua code: "},
    mypromptbox[mouse.screen].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval"
    )
end),
--[[
awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

awful.key({ modkey }, "x",
function ()
awful.prompt.run({ prompt = "Run Lua code: " },
mypromptbox[mouse.screen].widget,
awful.util.eval, nil,
awful.util.getdir("cache") .. "/history_eval")
end),
--]]

-- Menubar
--awful.key({ modkey }, "p", function() menubar.show() end)

-- personal customization
--{{
awful.key({ modkey, }, "Return", function ()
    awful.util.spawn(tools.terminal)
end),
awful.key({ modkey, "Mod1" }, "Return", function ()
    awful.util.spawn("gksudo " .. tools.terminal)
end),
awful.key({ modkey, }, "\\", function ()
    awful.util.spawn("xscreensaver-command -l")
end),

awful.key({ modkey, }, "i", function ()
    awful.util.spawn(tools.editor.primary)
end),
awful.key({ modkey, "Shift" }, "i", function ()
    awful.util.spawn(tools.editor.secondary)
end),

awful.key({ modkey, }, "b", function ()
    awful.util.spawn(tools.browser.primary)
end),
awful.key({ modkey, "Shift" }, "b", function ()
    awful.util.spawn(tools.browser.secondary)
end),

awful.key({ modkey }, "c", function () 
    awful.util.spawn(tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

awful.key({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(tools.system.filemanager)
end),

awful.key({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
end),
awful.key({ modkey }, "l", function ()
    awful.util.spawn("xfce4-appfinder")
end),
awful.key({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("VirtualBox")
end),

-- awful.key({                    }, "XF86AudioPrev", function () awful.util.spawn("mpc seek -5%") end),
awful.key({}, "XF86AudioPrev", function ()
    awful.util.spawn("mpc prev")
end),
-- awful.key({                    }, "XF86AudioNext", function () awful.util.spawn("mpc seek +5%") end),
awful.key({}, "XF86AudioNext", function ()
    awful.util.spawn("mpc next")
end),
awful.key({}, "XF86AudioPlay", function ()
    awful.util.spawn("mpc toggle")
end),
awful.key({}, "XF86AudioStop", function ()
    awful.util.spawn("mpc stop")
end),
awful.key({}, "XF86AudioRaiseVolume", function ()
    awful.util.spawn("amixer sset Master 5%+")
end),
awful.key({ modkey }, "XF86AudioRaiseVolume", function ()
    awful.util.spawn("amixer sset Mic 5%+")
end),
awful.key({}, "XF86AudioLowerVolume", function ()
    awful.util.spawn("amixer sset Master 5%-")
end),
awful.key({ modkey }, "XF86AudioLowerVolume", function ()
    awful.util.spawn("amixer sset Mic 5%-")
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
awful.key({}, "XF86MonBrightnessDown", function ()
    awful.util.spawn("xbacklight -dec 5")
end),
awful.key({}, "XF86MonBrightnessUp", function ()
    awful.util.spawn("xbacklight -inc 5")
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
awful.key({}, "XF86Launch1", function ()
    awful.util.spawn(tools.terminal)
end),
awful.key({ modkey }, "XF86Sleep", function ()
    awful.util.spawn("sudo systemctl hibernate")
end),

--{{ hacks for Thinkpad W530 FN mal-function

awful.key({ modkey }, "F10", function ()
    awful.util.spawn("mpc prev")
end),
awful.key({ modkey }, "F11", function ()
    awful.util.spawn("mpc toggle")
end),
awful.key({ modkey }, "F12", function ()
    awful.util.spawn("mpc next")
end),

awful.key({ modkey }, "Home", function ()
    awful.util.spawn("mpc seek -5%")
end),
awful.key({ modkey }, "End", function ()
    awful.util.spawn("mpc stop")
end),
awful.key({ modkey }, "Insert", function ()
    awful.util.spawn("mpc seek +5%")
end),

awful.key({ modkey, "Control" }, "Left", function ()
    awful.util.spawn("mpc prev")
end),
awful.key({ modkey, "Control" }, "Down", function ()
    awful.util.spawn("mpc toggle")
end),
awful.key({ modkey, "Control" }, "Right", function ()
    awful.util.spawn("mpc next")
end),
awful.key({ modkey, "Control" }, "Up", function ()
    awful.util.spawn("gnome-alsamixer")
end),

awful.key({ modkey, "Shift" }, "Left", function ()
    awful.util.spawn("mpc seek -1%")
end),
awful.key({ modkey, "Shift" }, "Right", function ()
    awful.util.spawn("mpc seek +1%")
end),
awful.key({ modkey, "Shift" }, "Down", function ()
    awful.util.spawn("mpc seek -10%")
end),
awful.key({ modkey, "Shift" }, "Up", function ()
    awful.util.spawn("mpc seek +10%")
end),
--}}
--}}
nil
)

clientkeys = awful.util.table.join(
awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
awful.key({ modkey, "Shift"   }, "t",      function (c) shifty.create_titlebar(c) awful.titlebar(c) c.border_width = 1 end),
awful.key({ modkey, "Shift"   }, "m",
function (c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
end),
awful.key({ modkey,           }, "m",
function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c.maximized_vertical   = not c.maximized_vertical
end)
)

-- SHIFTY: assign client keys to shifty for use in
-- match() function(manage hook)
shifty.config.clientkeys = clientkeys
shifty.config.modkey = modkey

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9, plus 0.

for i = 1, 10 do
    local keycode = "#" .. i+9

    globalkeys = awful.util.table.join(globalkeys,

    awful.key({ modkey }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            tag = shifty.add({
                index = #tags+1
            })
        end
        if tag then
            awful.tag.viewonly(tag)
        end
    end),

    awful.key({ modkey, "Control" }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            tag = shifty.add({
                index = #tags+1
            })
        end
        if tag then
            awful.tag.viewtoggle(tag)
        end
    end),

    awful.key({ modkey, "Shift" }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(client.focus.screen)
        if i <= #tags then
            tag = tags[i]
        else
            tag = shifty.add({
                index = #tags+1
            })
        end
        if client.focus and tag then
            awful.client.movetotag(tag)
        end
    end),

    awful.key({ modkey, "Control", "Shift" }, keycode,
    function ()
        local tag
        local tags = awful.tag.gettags(client.focus.screen)
        if i <= #tags then
            tag = tags[i]
        else
            tag = shifty.add({
                index = #tags+1
            })
        end
        if client.focus and tag then
            awful.client.toggletag(tag)
        end
    end),

    nil
    )
end

-- Set keys
root.keys(globalkeys)
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

    local titlebars_enabled = false
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
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

local function client_manage_tag(c, startup)
    if startup then
        local fname = awesome_restart_tags_fname .. '/' .. c.pid
        local f = io.open(fname, 'r')

        if f then
            local tags = {}
            for tag in io.lines(fname) do
                tags = awful.util.table.join(tags, {name2tag(tag)})
            end
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
client.connect_signal("manage", client_manage_tag)

-- }}}

-- disable startup-notification globally
-- prevent unintended mouse cursor change
awesome.orig.awful_util_spawn = awful.util.spawn
awful.util.spawn = function (s)
    awesome.orig.awful_util_spawn(s, false)
end

-- XDG style autostart with "dex"
-- HACK continue
awful.util.spawn_with_shell("if ! [ -e " .. awesome_autostart_once_fname .. " ]; then dex -a -e Awesome; touch " .. awesome_autostart_once_fname .. "; fi")
