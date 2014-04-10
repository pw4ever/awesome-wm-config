package.path = package.path .. ";./?/init.lua;"

local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
require("awful.dbus")
require("awful.remote")
awful.ewmh = require("awful.ewmh")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")

-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("bashets")

-- utilities
local util = require("util")

local capi = {
    tag = tag,
}

-- customization
customization = {}
customization.config = {}
customization.orig = {}
customization.func = {}
customization.default = {}
customization.option = {}
customization.timer = {}

customization.config.version = "1.5.3"
customization.config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. customization.config.version

customization.default.property = {
    layout = awful.layout.suit.floating,
    mwfact = 0.5,
    nmaster = 1,
    ncol = 1,
    min_opacity = 0.4,
    max_opacity = 1,
    default_naughty_opacity = 0.9,
}

customization.default.compmgr = 'xcompmgr'
customization.default.wallpaper_change_interval = 15

customization.option.wallpaper_change_p = true

naughty.config.presets.low.opacity = customization.default.property.default_naughty_opacity
naughty.config.presets.normal.opacity = customization.default.property.default_naughty_opacity
naughty.config.presets.critical.opacity = customization.default.property.default_naughty_opacity

do
    local config_path = awful.util.getdir("config")
    bashets.set_script_path(config_path .. "/bashets/")
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

    customization.orig.quit = awesome.quit
    awesome.quit = function ()
        local scr = mouse.screen
        awful.prompt.run({prompt = "Quit (type 'yes' to confirm)? "},
        mypromptbox[scr].widget,
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
                    f:write(awful.tag.getidx() .. "\n")
                    f:close()
                end
            end

            -- save tags for each client
            awful.util.mkdir(awesome_restart_tags_fname)
            -- !! avoid awful.util.spawn_with_shell("mkdir -p " .. awesome_restart_tags_fname) 
            -- race condition (whether awesome_restart_tags_fname is created) due to asynchrony of "spawn_with_shell"
            for _, c in ipairs(client.get()) do
                local client_id = c.pid .. '-' .. c.window
                local f = io.open(awesome_restart_tags_fname .. '/' .. client_id, 'w+')
                if f then
                    for _, t in ipairs(c:tags()) do
                        f:write(t.name .. "\n")
                    end
                    f:close()
                end
            end
        end
    end)

    customization.orig.restart = awesome.restart
    awesome.restart = function ()
        local scr = mouse.screen
        awful.prompt.run({prompt = "Restart (type 'yes' to confirm)? "},
        mypromptbox[scr].widget,
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
    terminal = "xfce4-terminal",
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

-- }}}

-- {{{ Wibox
mytextclock = wibox.widget.textbox()

-- http://awesome.naquadah.org/wiki/Bashets
bashets.register("date.sh", {widget=mytextclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"})

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
awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
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
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end),
awful.button({ }, 5, function ()
    awful.client.focus.byidx(1)
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
    awful.button({ }, 4, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, 1) end),
    nil
    ))
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

util.taglist.set_taglist(mytaglist)
-- }}}

do
    -- test whether screen 1 tag file exists
    local f = io.open(awesome_restart_tags_fname .. ".0", "r")
    if f then
        local old_scr_count = tonumber(f:read("*l"))
        f:close()
        os.remove(awesome_restart_tags_fname .. ".0")

        local new_scr_count = screen.count()

        local count = {}

        local scr_count = math.min(new_scr_count, old_scr_count)

        if scr_count>0 then
            for s = 1, scr_count do
                count[s] = 1
            end

            for s = 1, old_scr_count do
                local count_index = math.min(s, scr_count)
                local fname = awesome_restart_tags_fname .. "." .. s
                for tagname in io.lines(fname) do
                    local tag = awful.tag.add(tagname,
                    {
                        screen = s,
                        layout = customization.default.property.layout,
                        mwfact = customization.default.property.mwfact,
                        nmaster = customization.default.property.nmaster,
                        ncol = customization.default.property.ncol,
                    }
                    )
                    awful.tag.move(count[count_index], tag)

                    count[count_index] = count[count_index]+1
                end
                os.remove(fname)
            end
        end

        for s = 1, screen.count() do
            local fname = awesome_restart_tags_fname .. "-selected." .. s 
            f = io.open(fname, "r")
            if f then
                local tag = awful.tag.gettags(s)[tonumber(f:read("*l"))]
                if tag then
                    awful.tag.viewonly(tag)
                end
                f:close()
            end
            os.remove(fname)
        end

    else

        local tag = awful.tag.add("genesis",
        {
            screen = 1,
            layout = customization.default.property.layout,
            mwfact = customization.default.property.mwfact,
            nmaster = customization.default.property.nmaster,
            ncol = customization.default.property.ncol, 
        } 
        )
        awful.tag.viewonly(tag)

        awful.tag.add("nil",
        {
            screen = 2,
            layout = customization.default.property.layout,
            mwfact = customization.default.property.mwfact,
            nmaster = customization.default.property.nmaster,
            ncol = customization.default.property.ncol, 
        } 
        ) 

    end
end


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewprev),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(

-- window management

--- restart/quit/info

awful.key({ modkey, "Control" }, "r", awesome.restart),

awful.key({ modkey, "Shift"   }, "q", awesome.quit),

awful.key({ modkey }, "\\", function () 
    local info = "Version: " .. awesome.version 
    info = info ..  "\n" .. "Release: " .. awesome.release
    info = info ..  "\n" .. "Config: " .. awesome.conffile
    info = info ..  "\n" .. "Config Version: " .. customization.config.version 
    info = info ..  "\n" .. "Config Help: " .. customization.config.help_url
    if awesome.composite_manager_running then
        info = info .. "\n" .. "<span fgcolor='red'>a composite manager is running</span>"
    end
    local uname = awful.util.pread("uname -a")
    if string.gsub(uname, "%s", "") ~= "" then
        info = info .. "\n" .. "OS: " .. string.gsub(uname, "%s+$", "")
    end
    -- remove color code from screenfetch output
    local archey = awful.util.pread("screenfetch -N")
    if string.gsub(archey, "%s", "") ~= "" then
        info = info .. "\n\n<span face='monospace'>" .. archey .. "</span>"
    end
    info = string.gsub(info, "(%u[%a ]*:)%f[ ]", "<span color='red'>%1</span>")
    local tmp = awesome.composite_manager_running
    awesome.composite_manager_running = false
    naughty.notify({
        preset = naughty.config.presets.normal,
        title="awesome info",
        text=info,
        timeout = 10,
        screen = mouse.screen,
    })
    awesome.composite_manager_running = tmp
end),

awful.key({modkey}, "F1",
function ()
    local text = ""
    text = text .. "You are running awesome <span fgcolor='red'>" .. awesome.version .. "</span> (<span fgcolor='red'>" .. awesome.release .. "</span>)"
    text = text .. "\n" .. "with config version <span fgcolor='red'>" .. customization.config.version .. "</span>"
    text = text .. "\n\n" .. "help can be found at the URL: <u>" .. customization.config.help_url .. "</u>"
    text = text .. "\n\n\n\n" .. "opening in <b>" .. tools.browser.primary .. "</b>..."
    naughty.notify({
        preset = naughty.config.presets.normal,
        title="help about configuration",
        text=text,
        timeout = 20,
        screen = mouse.screen,
    })
    awful.util.spawn_with_shell(tools.browser.primary .. " '" .. customization.config.help_url .. "'")
end),

--- Layout

awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),

awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

--- multiple screens/multi-head/RANDR

awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),

awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),

awful.key({ modkey,           }, "o", awful.client.movetoscreen),

--- misc

awful.key({modkey}, "F2", function()
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

awful.key({ modkey }, "c", function () 
    awful.util.spawn(tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

awful.key({modkey,}, "/", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey,           }, "Return", function () awful.util.spawn(tools.terminal) end),

awful.key({ modkey, "Mod1" }, "Return", function () awful.util.spawn("gksudo " .. tools.terminal) end),

-- dynamic tagging

--- add/delete/rename

awful.key({modkey}, "a",
function ()
    local scr = mouse.screen
    local sel_idx = awful.tag.getidx()
    local t = util.tag.add(nil, 
    {
        screen = scr,
        index = sel_idx and sel_idx+1 or 1,
        layout = customization.default.property.layout,
        mwfact = customization.default.property.mwfact,
        nmaster = customization.default.property.nmaster,
        ncol = customization.default.property.ncol,
    })
end),

awful.key({modkey, "Shift"}, "a",
function ()
    local scr = mouse.screen
    local sel_idx = awful.tag.getidx()
    local t = util.tag.add(nil, 
    {
        screen = scr,
        index = sel_idx and sel_idx or 1,
        layout = customization.default.property.layout,
        mwfact = customization.default.property.mwfact,
        nmaster = customization.default.property.nmaster,
        ncol = customization.default.property.ncol,
    })
end),

awful.key({modkey, "Shift"}, "d", awful.tag.delete),

awful.key({modkey, "Shift"}, "r",
function ()
    local scr = mouse.screen
    local sel = awful.tag.selected(scr)
    util.tag.rename(sel)
end),

--- view

awful.key({modkey,}, "p", awful.tag.viewprev),

awful.key({modkey,}, "n", awful.tag.viewnext),

awful.key({modkey,}, "z", awful.tag.history.restore),

awful.key({modkey,}, "g",
function () 
    local keywords = {}
    local scr = mouse.screen
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Find tag: "},
    mypromptbox[scr].widget,
    function (t)
        awful.tag.viewonly(util.tag.name2tag(t))
    end,
    function (t, p, n)
        return awful.completion.generic(t, p, n, keywords)
    end)
end),

--- move

awful.key({modkey, "Control"}, "p", function () util.tag.rel_move(awful.tag.selected(), -1) end), 

awful.key({modkey, "Control"}, "n", function () util.tag.rel_move(awful.tag.selected(), 1) end), 

-- client management

--- change focus

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

awful.key({ modkey,           }, "Tab",
function ()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end),

awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),

--- swap order/select master

awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),

awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),

--- move/copy to tag

awful.key({modkey, "Shift"}, "p", function () util.client.rel_send(-1) end),

awful.key({modkey, "Shift"}, "n", function () util.client.rel_send(1) end),

awful.key({modkey, "Shift"}, "g",
function () 
    local keywords = {}
    local scr = mouse.screen
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    awful.prompt.run({prompt = "Move client to tag: "},
    mypromptbox[scr].widget,
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
end),

awful.key({modkey, "Control", "Shift"}, "g",
function () 
    local keywords = {}
    local scr = mouse.screen
    for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
        table.insert(keywords, t.name)
    end
    local c = client.focus
    awful.prompt.run({prompt = "Toggle tag for " .. c.name .. ": "},
    mypromptbox[scr].widget,
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
end),

--- change space allocation in tile layout

awful.key({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05) end),

awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05) end),

awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster( 1) end),

awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster(-1) end),

awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1) end),

awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1) end),

-- app bindings

--- admin

awful.key({ modkey, }, "`", function ()
    awful.util.spawn("xscreensaver-command -l")
end),

awful.key({ modkey }, "'", function ()
    awful.util.spawn("xfce4-appfinder")
end),

--- everyday

awful.key({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(tools.system.filemanager)
end),

awful.key({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
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

awful.key({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("virtualbox")
end),

--- the rest

awful.key({}, "XF86AudioPrev", function ()
    awful.util.spawn("mpc prev")
end),

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

awful.key({}, "XF86MonBrightnessUp", function ()
    awful.util.spawn("xbacklight -inc 5")
end),

awful.key({}, "XF86MonBrightnessDown", function ()
    awful.util.spawn("xbacklight -dec 5")
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
    awful.util.spawn("systemctl hibernate")
end),

--- hacks for Thinkpad W530 FN mal-function

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

nil

)

-- client management

--- operation
clientkeys = awful.util.table.join(

awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),

awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),

awful.key({ modkey,           }, "m",
function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c.maximized_vertical   = not c.maximized_vertical
end),

awful.key({ modkey, "Shift"   }, "m",
function (c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
end),

awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),


awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop end),

awful.key({ modkey,           }, "s",      function (c) c.sticky = not c.sticky end),

awful.key({ modkey,           }, ",",
function (c)
    c.maximized_horizontal = not c.maximized_horizontal
end),

awful.key({ modkey,           }, ".",
function (c)
    c.maximized_vertical   = not c.maximized_vertical
end),

awful.key({ modkey,           }, "[",
function (c)
    local opacity = c.opacity - 0.1
    if opacity and opacity >= customization.default.property.min_opacity then
        c.opacity = opacity
    end
end),

awful.key({ modkey,           }, "]",
function (c)
    local opacity = c.opacity + 0.1
    if opacity and opacity <= customization.default.property.max_opacity then
        c.opacity = opacity
    end
end),

awful.key({ modkey, 'Shift'   }, "[",
function (c)
    awful.util.spawn_with_shell("pkill " .. customization.default.compmgr)
end),

awful.key({ modkey, 'Shift'   }, "]",
function (c)
    awful.util.spawn_with_shell(customization.default.compmgr)
end),

awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),

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
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            local scr = mouse.screen
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            mypromptbox[scr].widget,
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
        local tags = awful.tag.gettags(mouse.screen)
        if i <= #tags then
            tag = tags[i]
        else
            local scr = mouse.screen
            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
            mypromptbox[scr].widget,
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
                local scr = mouse.screen
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                mypromptbox[scr].widget,
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
                local scr = mouse.screen
                awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                mypromptbox[scr].widget,
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
awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
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
        }
    },

    { rule = { class = "MPlayer" },
    properties = { 
        floating = true,
        opacity = 1,
    } },

    { rule = { class = "gimp" },
    properties = { floating = true } },

    --[[
    Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][2] } },
    --]]

    {
        rule = { class = "Conky" },
        properties = {
            sticky = true,
            opacity = 0.4,
        }
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
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

customization.func.client_manage_tag = function (c, startup)
    if startup then
        local client_id = c.pid .. '-' .. c.window

        local fname = awesome_restart_tags_fname .. '/' .. client_id
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
