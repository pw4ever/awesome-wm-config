local awful = require("awful")
local misc = require("../misc")
local util = require("../util")
local rudiment = require("../rudiment")
local naughty = require("naughty")
modkey = rudiment.modkey
numeric_keys = {}

function numeric_keys.new( numeric )
    local numkeys = nil
    for i = 0, 9 do
        local keycode = i
        numkeys = awful.util.table.join(numkeys,
        awful.key({}, keycode,
        function()
            numeric.argument = numeric.argument * 10 + i
        end)
        )
    end
   return awful.util.table.join(numkeys,


---numeric binding
awful.key({ modkey,  }, "u",
function ()
    numeric.factor = numeric:default()
    numeric.argument = 0
end),

-- toggle wibox visibility
 numeric:key_loop({ modkey }, "w", function ()
     mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
 end),

-- window management

--- restart/quit/info

numeric:key_loop({ modkey }, "\\", misc.notify.toggleAwesomeInfo),

numeric:key_loop({modkey}, "v", misc.notify.togglevolume),

numeric:key_loop({modkey}, "F1", misc.onlieHelp),

--- Layout

numeric:key_loop({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),

numeric:key_loop({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

--- multiple screens/multi-head/RANDR

numeric:key_loop({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),

numeric:key_loop({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),

numeric:key_loop({ modkey,           }, "o", awful.client.movetoscreen),

--- misc

-- NOTUSEFULL
numeric:key_argument({modkey}, "F2", function(number)
    awful.prompt.run(
    {prompt = "Run: "},
    mypromptbox[number].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),

numeric:key_argument({modkey}, "r", function(number)
    awful.prompt.run(
    {prompt = "Run: "},
    mypromptbox[number].widget,
    awful.util.spawn, awful.completion.shell,
    awful.util.getdir("cache") .. "/history"
    )
end),


numeric:key_argument({modkey}, "F4", function(number)
    awful.prompt.run(
    {prompt = "Run Lua code: "},
    mypromptbox[number].widget,
    awful.util.eval, misc.lua_completion,
    awful.util.getdir("cache") .. "/history_eval"
    )
end),

numeric:key_loop({ modkey }, "c", function ()
    awful.util.spawn(rudiment.tools.editor.primary .. " " .. awful.util.getdir("config") .. "/rc.lua" )
end),

-- repeating them is not cool
--[[
numeric:key_loop({ modkey, "Shift" }, "/", function() mymainmenu:toggle({keygrabber=true}) end),

numeric:key_loop({ modkey, }, ";", function()
  local c = client.focus
  if c then
    misc.client_action_menu(c)
  end
end),

numeric:key_loop({ modkey, "Shift" }, ";", misc.tag_action_menu),

numeric:key_loop({ modkey, }, "'", misc.clients_on_tag),

numeric:key_loop({ modkey, "Ctrl" }, "'", misc.clients_on_tag_prompt),

numeric:key_loop({ modkey, "Shift" }, "'", misc.all_clients),

numeric:key_loop({ modkey, "Shift", "Ctrl" }, "'", misc.all_clients_prompt),

numeric:key_loop({ modkey, }, "x", function() mymainmenu:toggle({keygrabber=true}) end),

numeric:key_loop({ modkey, }, "X", function() mymainmenu:toggle({keygrabber=true}) end),

--]]

numeric:key_loop({ modkey,           }, "Return", function () awful.util.spawn(rudiment.tools.terminal) end),

numeric:key_loop({ modkey, "Mod1" }, "Return", function () awful.util.spawn("gksudo " .. rudiment.tools.terminal) end),

-- dynamic tagging

--- add/delete/rename

numeric:key_loop({modkey}, "a", misc.tag_add_after),

numeric:key_loop({modkey, "Shift"}, "a", misc.tag_add_before),

-- may be dangerous
numeric:key_loop({modkey, "Shift"}, "d", misc.tag_delete),

numeric:key_loop({modkey, "Shift"}, "r", misc.tag_rename),

--- view
-- NOT EXACTLY SAME
numeric:key_loop({modkey,}, "p", misc.util.compose(awful.tag.viewidx, misc.util.negate)),

numeric:key_argument({modkey,}, "n", awful.tag.viewidx ),

-- NOTUSEFULL
numeric:key_loop({modkey,}, "z", misc.tag_last),

-- NOTUSEFULL
numeric:key_loop({modkey,}, "g", misc.tag_goto),

--- move

numeric:key_argument({modkey, "Control"}, "p",  function (n)
                util.tag.rel_move(awful.tag.selected(), -n)  end),

numeric:key_argument({modkey, "Control"}, "n", function (n)
                util.tag.rel_move(awful.tag.selected(), n)  end),

-- client management

--- change focus
-- NOT EXACTLY SAME
numeric:key_argument({ modkey,           }, "j", misc.client_focus_next_n),

numeric:key_argument({ modkey,           }, "Tab", misc.client_focus_next_n),

numeric:key_argument({ modkey,           }, "k", misc.util.compose( misc.client_focus_prev, misc.util.negate )),

numeric:key_argument({ modkey, "Shift"   }, "Tab", misc.util.compose( misc.client_focus_prev, misc.util.negate )),

-- NOTUSEFULL
numeric:key_loop({ modkey,           }, "y", misc.client_focus_urgent),

--- swap order/select master

numeric:key_argument({ modkey, "Shift"   }, "j", awful.client.swap.byidx),

numeric:key_argument({ modkey, "Shift"   }, "k", misc.util.compose( awful.client.swap.byidx, misc.util.negate)),

--- move/copy to tag

numeric:key_argument({modkey, "Shift"}, "n", util.client.rel_send),

numeric:key_argument({modkey, "Shift"}, "p", misc.util.compose(util.client.rel_send, misc.util.negate)),

-- NOTUSEFULL
numeric:key_loop({modkey, "Shift"}, "g", misc.client_move_to_tag),

-- NOTUSEFULL
numeric:key_loop({modkey, "Control", "Shift"}, "g", misc.client_toggle_tag),

--- change space allocation in tile layout

numeric:key_loop({ modkey, }, "=", function () awful.tag.setmwfact(0.5) end),

numeric:key_argument({ modkey,           }, "l",     function (n) awful.tag.incmwfact( 0.01*n) end),

numeric:key_argument({ modkey,           }, "h",     function (n) awful.tag.incmwfact(-0.01*n) end),

numeric:key_argument({ modkey, "Shift"   }, "l",     function (n) awful.tag.incnmaster( 1*n) end),

numeric:key_argument({ modkey, "Shift"   }, "h",     function (n) awful.tag.incnmaster(-1*n) end),

numeric:key_argument({ modkey, "Control" }, "l",     function () awful.tag.incncol( 1*n) end),

numeric:key_argument({ modkey, "Control" }, "h",     function () awful.tag.incncol(-1*n) end),

--- misc
-- NOTUSEFULL
numeric:key_loop({ modkey, "Shift" }, "`", misc.client_toggle_titlebar),

-- app bindings

--- admin

--numeric:key_loop({ modkey, }, "`", misc.system_lock),
--
--numeric:key_loop({ modkey, }, "Home", misc.system_lock),
--
--numeric:key_loop({ modkey, }, "End", misc.system_suspend),
--
--numeric:key_loop({ modkey,  "Mod1" }, "Home", misc.system_hibernate),
--
--numeric:key_loop({ modkey,  "Mod1" }, "End", misc.system_hybrid_sleep),
--
--numeric:key_loop({ modkey, }, "Insert", misc.system_reboot),
--
--numeric:key_loop({ modkey, }, "Delete", misc.system_power_off),

numeric:key_loop({ modkey, }, "/", misc.app_finder),

--- everyday

numeric:key_loop({ modkey, "Mod1", }, "l", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

numeric:key_loop({ modkey,  }, "e", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

numeric:key_loop({ modkey,  }, "E", function ()
    awful.util.spawn(rudiment.tools.system.filemanager)
end),

numeric:key_loop({ modkey, "Mod1", }, "p", function ()
    awful.util.spawn("putty")
end),

numeric:key_loop({ modkey, "Mod1", }, "r", function ()
    awful.util.spawn("remmina")
end),

numeric:key_loop({ modkey, }, "i", function ()
    awful.util.spawn(rudiment.tools.editor.primary)
end),

numeric:key_loop({ modkey, "Shift" }, "i", function ()
    awful.util.spawn(rudiment.tools.editor.secondary)
end),

numeric:key_loop({ modkey, }, "b", function ()
    awful.util.spawn(rudiment.tools.browser.primary)
end),

numeric:key_loop({ modkey, "Shift" }, "b", function ()
    awful.util.spawn(rudiment.tools.browser.secondary)
end),

numeric:key_loop({ modkey, "Mod1", }, "v", function ()
    awful.util.spawn("virtualbox")
end),

numeric:key_loop({modkey, "Shift" }, "\\", function()
    awful.util.spawn("kmag")
end),

--- the rest

numeric:key_loop({}, "XF86TouchpadToggle", function()
    awful.util.spawn_with_shell(rudiment.config_path .. "/bin/trackpad-toggle.sh")
end),

numeric:key_loop({}, "XF86AudioPrev", function ()
    awful.util.spawn("mpc prev")
end),

numeric:key_loop({}, "XF86AudioNext", function ()
    awful.util.spawn("mpc next")
end),

numeric:key_loop({}, "XF86AudioPlay", function ()
    awful.util.spawn("mpc toggle")
end),

numeric:key_loop({}, "XF86AudioStop", function ()
    awful.util.spawn("mpc stop")
end),

numeric:key_argument({}, "XF86AudioRaiseVolume",   misc.Volume.Up_n),

numeric:key_loop({ modkey }, "XF86AudioRaiseVolume", function ()
    awful.util.spawn("amixer sset Mic 5%+")
end),

numeric:key_argument({}, "XF86AudioLowerVolume", misc.util.compose(misc.Volume.Up_n, misc.util.negate) ),

numeric:key_loop({}, "XF86AudioMute", function ()
    awful.util.spawn("amixer sset Master toggle")
end),

numeric:key_loop({}, "XF86AudioMicMute", function ()
    awful.util.spawn("amixer sset Mic toggle")
end),

numeric:key_loop({}, "XF86ScreenSaver", function ()
    awful.util.spawn("xscreensaver-command -l")
end),

numeric:key_loop({}, "XF86WebCam", function ()
    awful.util.spawn("cheese")
end),
--TODO
numeric:key_loop({}, "XF86MonBrightnessUp", function ()
    awful.util.spawn("xbacklight -inc 10")
end),

numeric:key_loop({}, "XF86MonBrightnessDown", function ()
    awful.util.spawn("xbacklight -dec 10")
end),

numeric:key_loop({}, "XF86WLAN", function ()
    awful.util.spawn("nm-connection-editor")
end),

numeric:key_loop({}, "XF86Display", function ()
    awful.util.spawn("arandr")
end),

numeric:key_loop({}, "Print", function ()
    awful.util.spawn("xfce4-screenshooter")
end),

numeric:key_loop({}, "XF86Launch1", function ()
    awful.util.spawn(rudiment.tools.terminal)
end),

numeric:key_loop({ }, "XF86Sleep", function ()
    awful.util.spawn("systemctl suspend")
end),


numeric:key_loop({ modkey }, "XF86Sleep", function ()
    awful.util.spawn("systemctl hibernate")
end),

--- hacks for Thinkpad W530 FN mal-function

numeric:key_loop({ modkey }, "F10", function ()
    awful.util.spawn("mpc prev")
end),

numeric:key_loop({ modkey }, "F11", function ()
    awful.util.spawn("mpc toggle")
end),

numeric:key_loop({ modkey }, "F12", function ()
    awful.util.spawn("mpc next")
end),

numeric:key_loop({ modkey, "Control" }, "Left", function ()
    awful.util.spawn("mpc prev")
end),

numeric:key_loop({ modkey, "Control" }, "Down", function ()
    awful.util.spawn("mpc toggle")
end),

numeric:key_loop({ modkey, "Control" }, "Right", function ()
    awful.util.spawn("mpc next")
end),

numeric:key_loop({ modkey, "Control" }, "Up", function ()
    awful.util.spawn("gnome-alsamixer")
end),

numeric:key_loop({ modkey, "Shift" }, "Left", function ()
    awful.util.spawn("mpc seek -1%")
end),

numeric:key_loop({ modkey, "Shift" }, "Right", function ()
    awful.util.spawn("mpc seek +1%")
end),

numeric:key_loop({ modkey, "Shift" }, "Down", function ()
    awful.util.spawn("mpc seek -10%")
end),

numeric:key_loop({ modkey, "Shift" }, "Up", function ()
    awful.util.spawn("mpc seek +10%")
end),

nil

)
,
-- client management

--- operation
awful.util.table.join(

numeric:key_loop({ modkey, "Shift"   }, "c", misc.client_kill),

numeric:key_loop({ "Mod1",   }, "F4", misc.client_kill),

numeric:key_loop({ modkey,           }, "f", misc.client_fullscreen),

numeric:key_loop({ modkey,           }, "m", misc.client_maximize),

-- move client to sides, i.e., sidelining

numeric:key_loop({ modkey,           }, "Left", misc.client_sideline_left),

numeric:key_loop({ modkey,           }, "Right", misc.client_sideline_right),

numeric:key_loop({ modkey,           }, "Up", misc.client_sideline_top),

numeric:key_loop({ modkey,           }, "Down", misc.client_sideline_bottom),

-- extend client sides

numeric:key_argument({ modkey, "Mod1"    }, "Left", misc.client_sideline_extend_left_n),

numeric:key_argument({ modkey, "Mod1"    }, "Right", misc.client_sideline_extend_right_n),

numeric:key_argument({ modkey, "Mod1"    }, "Up", misc.client_sideline_extend_top_n),

numeric:key_argument({ modkey, "Mod1"    }, "Down", misc.client_sideline_extend_bottom_n),

-- shrink client sides

numeric:key_argument({ modkey, "Mod1", "Shift" }, "Left", misc.client_sideline_shrink_left_n),

numeric:key_argument({ modkey, "Mod1", "Shift" }, "Right", misc.client_sideline_shrink_right_n),

numeric:key_argument({ modkey, "Mod1", "Shift" }, "Up", misc.client_sideline_shrink_top_n),

numeric:key_argument({ modkey, "Mod1", "Shift" }, "Down", misc.client_sideline_shrink_bottom_n),

-- maximize/minimize

numeric:key_loop({ modkey, "Shift"   }, "m", misc.client_minimize),

numeric:key_loop({ modkey, "Control" }, "space",  awful.client.floating.toggle),


numeric:key_loop({ modkey,           }, "t", misc.client_toggle_top),

numeric:key_loop({ modkey,           }, "s", misc.client_toggle_sticky),

numeric:key_loop({ modkey,           }, ",", misc.client_maximize_horizontal),

numeric:key_loop({ modkey,           }, ".", misc.client_maximize_vertical),

numeric:key_argument({ modkey,           }, "[", misc.client_opaque_less_n),

numeric:key_argument({ modkey,           }, "]", misc.client_opaque_more_n),

numeric:key_loop({ modkey, 'Shift'   }, "[", misc.client_opaque_off),

numeric:key_loop({ modkey, 'Shift'   }, "]", misc.client_opaque_on),

numeric:key_loop({ modkey, "Control" }, "Return", misc.client_swap_with_master),

nil

)

end

return numeric_keys
