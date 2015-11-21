package.path = package.path .. ";./?/init.lua;"

local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
awful.menu = require("awful.menu")
require("awful.autofocus")
require("awful.dbus")
require("awful.remote")
awful.ewmh = require("awful.ewmh")
local wibox = require("wibox")
local beautiful = require("beautiful")
local menubar = require("menubar")

-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("bashets")

-- utilities
local util = require("util")

local capi = {
    tag = tag,
    screen = screen,
    client = client,
}

local customization = {}
customization.config = {}
customization.orig = {}
local rudiment = require("rudiment")
modkey = rudiment.modkey
local misc = require("misc")

local naughty = require("naughty")
numeric_keys = require("numeric_keys")

-- do not use letters, which shadow access key to menu entry
awful.menu.menu_keys.down = { "Down", ".", ">", "'", "\"", }
awful.menu.menu_keys.up = {  "Up", ",", "<", ";", ":", }
awful.menu.menu_keys.enter = { "Right", "]", "}", "=", "+", }
awful.menu.menu_keys.back = { "Left", "[", "{", "-", "_", }
awful.menu.menu_keys.exec = { "Return", "Space", }
awful.menu.menu_keys.close = { "Escape", "BackSpace", }

bashets.set_script_path(rudiment.config_path .. "/bashets/")



-- VimAw configuration file
local config = require("vimaw.config")


-- Run VimAw
local VimAw = require("vimaw.VimAw")

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
    --[[
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
    --]]

end

-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
---[[

do
    local function init_theme(theme_name)
        local theme_path = rudiment.config_path .. "/themes/" .. theme_name .. "/theme.lua"
        beautiful.init(theme_path)
    end
    init_theme("zenburn")
    awful.util.spawn_with_shell("hsetroot -solid '#000000'")
end
--]]

-- This is used later as the default terminal and editor to run.

--{{

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
    myapp = build(rudiment.tools)
end
--}}


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


-- }}

-- }}}

-- {{{ Menu

-- Create a launcher widget and a main menu
local mysystemmenu = {
    --{ "manual", tools.terminal .. " -e man awesome" },
    { "&lock", misc.system_lock },
    { "&suspend", misc.system_suspend },
    { "hi&bernate", misc.system_hibernate },
    { "hybri&d sleep", misc.system_hybrid_sleep },
    { "&reboot", misc.system_reboot },
    { "&power off", misc.system_power_off }
}

-- Create a launcher widget and a main menu
local myawesomemenu = {
    --{ "manual", tools.terminal .. " -e man awesome" },
    { "&edit config", rudiment.tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
    { "&restart", awesome.restart },
    { "&quit", awesome.quit }
}

local mymainmenu = awful.menu({
  theme = { width=150, },
  items = {
    { "&system", mysystemmenu },
    { "app &finder", misc.app_finder },
    { "&apps", myapp },
    { "&terminal", rudiment.tools.terminal },
    { "a&wesome", myawesomemenu, beautiful.awesome_icon },
    { "&client action", function ()
      misc.client_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "&tag action", function ()
      misc.tag_action_menu()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients &on current tag", function ()
      misc.clients_on_tag()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
    { "clients on a&ll tags", function ()
      misc.all_clients()
      mymainmenu:hide()
    end, beautiful.awesome_icon },
  }
})

local mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
menu = mymainmenu })

-- }}}

-- {{{ Wibox
mytextclock = wibox.widget.textbox()
mytextbattery = wibox.widget.textbox()

-- http://awesome.naquadah.org/wiki/Bashets
bashets.register("date.sh", {widget=mytextclock, update_time=1, format="$1 <span fgcolor='red'>$2</span> <small>$3$4</small> <b>$5<small>$6</small></b>"})
bashets.register("battery.sh", {widget=mytextbattery, update_time=10, format="<span fgcolor='yellow'>$1</span>"})
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
awful.button({ }, 1, awful.tag.viewonly),
awful.button({ modkey }, 1, awful.client.movetotag),
awful.button({ }, 2, awful.tag.viewtoggle),
awful.button({ modkey }, 2, awful.client.toggletag),
awful.button({ }, 3, function (t)
  misc.tag_action_menu(t)
end),
awful.button({ modkey }, 3, awful.tag.delete),
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

awful.button({ }, 2, function (c)
  misc.clients_on_tag()
end),

awful.button({ modkey }, 2, function (c)
    misc.all_clients()
end),

awful.button({ }, 3, function (c)
  misc.client_action_menu(c)
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
    mywibox[s] = awful.wibox({ position = "top", screen = s, ontop = true })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextbattery)
    right_layout:add(mytextclock)
    right_layout:add(VimAw.modeBox)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
    mywibox[s].visible=false
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
                        screen = count_index,
                        layout = rudiment.default.property.layout,
                        mwfact = rudiment.default.property.mwfact,
                        nmaster = rudiment.default.property.nmaster,
                        ncol = rudiment.default.property.ncol,
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
            layout = rudiment.default.property.layout,
            mwfact = rudiment.default.property.mwfact,
            nmaster = rudiment.default.property.nmaster,
            ncol = rudiment.default.property.ncol,
        }
        )
        awful.tag.viewonly(tag)

        awful.tag.add("nil",
        {
            screen = 2,
            layout = rudiment.default.property.layout,
            mwfact = rudiment.default.property.mwfact,
            nmaster = rudiment.default.property.nmaster,
            ncol = rudiment.default.property.ncol,
        }
        )

    end
end


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
awful.button({ }, 1, misc.all_clients),
awful.button({ }, 2, misc.tag_action_menu),
awful.button({ }, 3, function () mymainmenu:toggle() end),
awful.button({ }, 4, awful.tag.viewprev),
awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
toggleNotifylist = {}
-- {{{ Key bindings

-- object creation
local n_binding = misc.binding.numeric:new({ argument = 0, factor = 1 } )
local ngkeys, nckeys =  numeric_keys.new(n_binding)
globalkeys = awful.util.table.join(

---numeric binding
awful.key({ modkey}, "u",
function ()
    n_binding:start(
         function ()
        root.keys(ngkeys)
        client.focus:keys(nckeys)
           end ,
        function ()
           root.keys( globalkeys)
           client.focus:keys(clientkeys)
           n_binding.factor = 1
           n_binding.argument = 0
       end)
end),

    -------------------------------------------------- !!!!!!!!!!!!!!!!!!!!
    -- Shortcut for returning to NORMAL MODE
    awful.key({ modkey,           }, "Escape", function () normalMode() end),
    awful.key({ "Control", "Mod1" }, "[", function () normalMode() end),
    -------------------------------------------------- !!!!!!!!!!!!!!!!!!!!

-- toggle wibox visibility
 awful.key({ modkey }, "w", function ()
     mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
 end),

-- window management

--- restart/quit/info

awful.key({ modkey, "Control" }, "r", awesome.restart),

awful.key({ modkey, "Shift"   }, "q", awesome.quit),

awful.key({ modkey }, "\\", misc.notify.toggleAwesomeInfo),

awful.key({modkey}, "v", misc.notify.togglevolume),

awful.key({modkey}, "F1", misc.onlieHelp),

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

awful.key({modkey}, "r", function()
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
    awful.util.eval, misc.lua_completion,
    awful.util.getdir("cache") .. "/history_eval"
    )
end),

awful.key({ modkey }, "c", function ()
    awful.util.spawn(rudiment.tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

awful.key({ modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, ";", function()
  local c = client.focus
  if c then
    misc.client_action_menu(c)
  end
end),

awful.key({ modkey, "Shift" }, ";", misc.tag_action_menu),

awful.key({ modkey, }, "'", misc.clients_on_tag),

awful.key({ modkey, "Ctrl" }, "'", misc.clients_on_tag_prompt),

awful.key({ modkey, "Shift" }, "'", misc.all_clients),

awful.key({ modkey, "Shift", "Ctrl" }, "'", misc.all_clients_prompt),

awful.key({ modkey, }, "x", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey, }, "X", function() mymainmenu:toggle({keygrabber=true}) end),

awful.key({ modkey,           }, "Return", function () awful.util.spawn(rudiment.tools.terminal) end),

awful.key({ modkey, "Mod1" }, "Return", function () awful.util.spawn("gksudo " .. rudiment.tools.terminal) end),

-- dynamic tagging

--- add/delete/rename

awful.key({modkey}, "a", misc.tag_add_after),

awful.key({modkey, "Shift"}, "a", misc.tag_add_before),

awful.key({modkey, "Shift"}, "d", misc.tag_delete),

awful.key({modkey, "Shift"}, "r", misc.tag_rename),

--- view

awful.key({modkey,}, "p", misc.tag_view_prev),

awful.key({modkey,}, "n", misc.tag_view_next),

awful.key({modkey,}, "z", misc.tag_last),

awful.key({modkey,}, "g", misc.tag_goto),

--- move

awful.key({modkey, "Control"}, "p", misc.tag_move_backward),

awful.key({modkey, "Control"}, "n", misc.tag_move_forward),

-- client management

--- change focus

awful.key({ modkey,           }, "j", misc.client_focus_next),

awful.key({ modkey,           }, "Tab", misc.client_focus_next),

awful.key({ modkey,           }, "k", misc.client_focus_prev),

awful.key({ modkey, "Shift"   }, "Tab", misc.client_focus_prev),

awful.key({ modkey,           }, "y", misc.client_focus_urgent),

--- swap order/select master

awful.key({ modkey, "Shift"   }, "j", misc.client_swap_next),

awful.key({ modkey, "Shift"   }, "k", misc.client_swap_prev),

--- move/copy to tag

awful.key({modkey, "Shift"}, "n", misc.client_move_next),

awful.key({modkey, "Shift"}, "p", misc.client_move_prev),

awful.key({modkey, "Shift"}, "g", misc.client_move_to_tag),

awful.key({modkey, "Control", "Shift"}, "g", misc.client_toggle_tag),

--- change space allocation in tile layout

awful.key({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05) end),

awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05) end),

awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster( 1) end),

awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster(-1) end),

awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1) end),

awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1) end),

--- misc

awful.key({ modkey, "Shift" }, "`", misc.client_toggle_titlebar),

-- app bindings

--- admin

awful.key({ modkey, }, "`", misc.system_lock),

awful.key({ modkey, }, "Home", misc.system_lock),

awful.key({ modkey, }, "End", misc.system_suspend),

awful.key({ modkey,  "Mod1" }, "Home", misc.system_hibernate),

awful.key({ modkey,  "Mod1" }, "End", misc.system_hybrid_sleep),

awful.key({ modkey, }, "Insert", misc.system_reboot),

awful.key({ modkey, }, "Delete", misc.system_power_off),

awful.key({ modkey, }, "/", misc.app_finder),

--- everyday

awful.key({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

awful.key({ modkey,  }, "e", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

awful.key({ modkey,  }, "E", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

awful.key({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
end),

awful.key({ modkey, "Mod1", }, "r", function ()
    awful.util.spawn("remmina")
end),

awful.key({ modkey, }, "i", function ()
    awful.util.spawn(rudiment.tools.editor.primary)
end),

awful.key({ modkey, "Shift" }, "i", function ()
    awful.util.spawn(rudiment.tools.editor.secondary)
end),

awful.key({ modkey, }, "b", function ()
    awful.util.spawn(rudiment.tools.browser.primary)
end),

awful.key({ modkey, "Shift" }, "b", function ()
    awful.util.spawn(rudiment.tools.browser.secondary)
end),

awful.key({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("virtualbox")
end),

awful.key({modkey, "Shift" }, "\\", function()
    awful.util.spawn("kmag")
end),

--- the rest

awful.key({}, "XF86TouchpadToggle", function()
    awful.util.spawn_with_shell(rudiment.config_path .. "/bin/trackpad-toggle.sh")
end),

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
    misc.Volume.Up()
end),

awful.key({ modkey }, "XF86AudioRaiseVolume", function ()
    awful.util.spawn("amixer sset Mic 5%+")
end),

awful.key({}, "XF86AudioLowerVolume", function ()
    misc.Volume.Down()
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
    awful.util.spawn("xbacklight -inc 10")
end),

awful.key({}, "XF86MonBrightnessDown", function ()
    awful.util.spawn("xbacklight -dec 10")
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
    awful.util.spawn(rudiment.tools.terminal)
end),

awful.key({ }, "XF86Sleep", function ()
    awful.util.spawn("systemctl suspend")
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

awful.key({ modkey, "Shift"   }, "c", misc.client_kill),

awful.key({ "Mod1",   }, "F4", misc.client_kill),

awful.key({ modkey,           }, "f", misc.client_fullscreen),

awful.key({ modkey,           }, "m", misc.client_maximize),

-- move client to sides, i.e., sidelining

awful.key({ modkey,           }, "Left", misc.client_sideline_left),

awful.key({ modkey,           }, "Right", misc.client_sideline_right),

awful.key({ modkey,           }, "Up", misc.client_sideline_top),

awful.key({ modkey,           }, "Down", misc.client_sideline_bottom),

-- extend client sides

awful.key({ modkey, "Mod1"    }, "Left", misc.client_sideline_extend_left),

awful.key({ modkey, "Mod1"    }, "Right", misc.client_sideline_extend_right),

awful.key({ modkey, "Mod1"    }, "Up", misc.client_sideline_extend_top),

awful.key({ modkey, "Mod1"    }, "Down", misc.client_sideline_extend_bottom),

-- shrink client sides

awful.key({ modkey, "Mod1", "Shift" }, "Left", misc.client_sideline_shrink_left),

awful.key({ modkey, "Mod1", "Shift" }, "Right", misc.client_sideline_shrink_right),

awful.key({ modkey, "Mod1", "Shift" }, "Up", misc.client_sideline_shrink_top),

awful.key({ modkey, "Mod1", "Shift" }, "Down", misc.client_sideline_shrink_bottom),

-- maximize/minimize

awful.key({ modkey, "Shift"   }, "m", misc.client_minimize),

awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle),


awful.key({ modkey,           }, "t", misc.client_toggle_top),

awful.key({ modkey,           }, "s", misc.client_toggle_sticky),

awful.key({ modkey,           }, ",", misc.client_maximize_horizontal),

awful.key({ modkey,           }, ".", misc.client_maximize_vertical),

awful.key({ modkey,           }, "[", misc.client_opaque_less),

awful.key({ modkey,           }, "]", misc.client_opaque_more),

awful.key({ modkey, 'Shift'   }, "[", misc.client_opaque_off),

awful.key({ modkey, 'Shift'   }, "]", misc.client_opaque_on),

awful.key({ modkey, "Control" }, "Return", misc.client_swap_with_master),

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

-- globalgrabber = awful.keygrabber.run(misc.keys2CallbackFunction(globalkeys))
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
            opacity = rudiment.default.property.default_naughty_opacity,
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

client.connect_signal("manage", misc.client_manage_tag)

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
