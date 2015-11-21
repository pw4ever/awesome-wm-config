-- functions that provides certain functionality in this file
package.path = package.path .. ";./?/init.lua;"

local awful = require("awful")
awful.menu = require("awful.menu")
local naughty = require("naughty")
local rudiment = require("../rudiment")
local util = require("../util")
-- some miscellaneous functions
misc = {}

-- my own notification. Turn previous notification off if used again
misc.notify =  {}
misc.notify.togglelist = {}

misc.Volume = {}
misc.Volume.step = "1%"
misc.Volume.control = "Master"

misc.timer = {}

misc.binding = {}
misc.binding.numeric = {}
misc.binding.numeric.argument = 0
misc.binding.numeric.factor = 1
misc.util = {}
misc.resize_step = 1
misc.opaque_step = 0.1

function misc.binding.numeric:new (o)
    o = o or {}   -- create object if user does not provide one setmetatable(o, self)
    setmetatable(o, self)
    self.__index = self
    return o
end

---the default is a emacs like method
function misc.binding.numeric:default()
    if self.argument == 0 then
        return 4 * self.factor
    else
        return self.argument * self.factor
    end
end


-- first function apply this bindings
-- second go back to parent
function misc.binding.numeric:start( numeric_Callback, parent_Callback )
    -- this function can be used to return to this binding
    self.binding = numeric_Callback
    numeric_Callback()
    self.stop = parent_Callback
end

-- add key whose callback get looped certain times
function misc.binding.numeric:key_loop ( mods, key, callback)
    return awful.key(mods, key,
    function (...)
        local num = self:default()
        for i = 1, num do
            callback(...)
        end
    self.stop()
    end)
end

-- add key with numeric argument
function misc.binding.numeric:key_argument (mods, key, callback)
    return awful.key(mods, key,
    function (...)
        callback(self:default(), ...)
        self.stop()
    end)
end

function misc.notify.togglenotify( key, option)
    if misc.notify.togglelist[key] then
        naughty.destroy(misc.notify.togglelist[key])
        misc.notify.togglelist[key] = nil
        return
    end
    misc.notify.togglelist[key] = naughty.notify(options)
end
function misc.notify.volume (options)
    local vol = "<span face='monospace'>" .. awful.util.pread("myscripts/showvol.sh") .. "</span>"
    options = awful.util.table.join(options, {
        preset = naughty.config.presets.normal,
        title="Volume Info",
        text=vol,
        timeout = 0,
        screen = mouse.screen,
    })
    misc.notify.togglelist.volnotify = naughty.notify(options)
end

function misc.notify.togglevolume ()
    local vol = "<span face='monospace'>" .. awful.util.pread("myscripts/showvol.sh") .. "</span>"
    options = awful.util.table.join(options, {
        preset = naughty.config.presets.normal,
        title="Volume Info",
        text=vol,
        timeout = 0,
        screen = mouse.screen,
    })
    misc.notify.togglenotify("volnotify",options)
end

function misc.notify.toggleAwesomeInfo()

    if misc.notify.togglelist.awesomeInfo then
        naughty.destroy(misc.notify.togglelist.awesomeInfo)
        misc.notify.togglelist.awesomeInfo = nil
        return
    end

    local info = "Version: " .. awesome.version
    info = info ..  "\n" .. "Release: " .. awesome.release
    info = info ..  "\n" .. "Config: " .. awesome.conffile
    info = info ..  "\n" .. "Config Version: " .. rudiment.config.version
    info = info ..  "\n" .. "Config Help: " .. rudiment.config.help_url
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
    misc.notify.togglelist.awesomeInfo = naughty.notify({
        preset = naughty.config.presets.normal,
        title="awesome info",
        text=info,
        timeout = 10,
        screen = mouse.screen,
    })
    awesome.composite_manager_running = tmp
end





function misc.Volume.Change (Master, step, dire)
    awful.util.spawn("amixer sset " .. Master .. " " .. step .. dire)
    if misc.notify.togglelist.volnotify then
        misc.notify.volume({replaces_id = misc.notify.togglelist.volnotify.id})
    end
end

function misc.Volume.Up ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "+")
end

function misc.Volume.Down ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "-")
end

function misc.Volume.Up_n (n)
    misc.Volume.Change(misc.Volume.control, n*misc.Volume.step, "+")
end

--

-- hack for lua eval
function misc.lua_completion (line, cur_pos, ncomp)
   -- Only complete at the end of the line, for now
   if cur_pos ~= #line + 1 then
      return line, cur_pos
   end

   -- We're really interested in the part following the last (, [, comma or space
   local lastsep = #line - (line:reverse():find('[[(, ]') or #line)
   local lastidentifier
   if lastsep ~= 0 then
      lastidentifier = line:sub(lastsep + 2)
   else
      lastidentifier = line
   end

   local environment = _G

   -- String up to last dot is our current environment
   local lastdot = #lastidentifier - (lastidentifier:reverse():find('.', 1, true) or #lastidentifier)
   if lastdot ~= 0 then
      -- We have an environment; for each component in it, descend into it
      for env in lastidentifier:sub(1, lastdot):gmatch('([^.]+)') do
         if not environment[env] then
            -- Oops, no such subenvironment, bail out
            return line, cur_pos
         end
         environment = environment[env]
      end
   end

   local tocomplete = lastidentifier:sub(lastdot + 1)
   if tocomplete:sub(1, 1) == '.' then
      tocomplete = tocomplete:sub(2)
   end
   local completions = {}
   for k, v in pairs(environment) do
      if type(k) == "string" and k:sub(1, #tocomplete) == tocomplete then
         table.insert(completions, k)
      end
   end

   if #completions == 0 then
      return line, cur_pos
   end
   while ncomp > #completions do
      ncomp = ncomp - #completions
   end

   local str = ""
   if lastdot + lastsep ~= 0 then
      str = line:sub(1, lastsep + lastdot + 1)
   end
   str = str .. completions[ncomp]
   cur_pos = #str + 1
   return str, cur_pos
end

function misc.usefuleval(s)
    local f, err = loadstring("return "..s);
    if not f then
        f, err = loadstring(s);
    end
    if f then
        setfenv(f, _G);
        local ret = { pcall(f) };
        if ret[1] then
            -- Ok
            table.remove(ret, 1)
            local highest_index = #ret;
            for k, v in pairs(ret) do
                if type(k) == "number" and k > highest_index then
                    highest_index = k;
                end
                ret[k] = select(2, pcall(tostring, ret[k])) or "<no value>";
            end
            -- Fill in the gaps
            for i = 1, highest_index do
                if not ret[i] then
                    ret[i] = "nil"
                end
            end
            if highest_index > 0 then
                naughty.notify({ awful.util.escape("Result"..(highest_index > 1 and "s" or "")..": "..tostring(table.concat(ret, ", "))), screen = mouse.screen});
            else
                naughty.notify({ "Result: Nothing", screen = mouse.screen})
            end
        else
            err = ret[2];
        end
    end
    if err then
        naughty.notify({ awful.util.escape("Error: "..tostring(err)), screen = mouse.screen})
    end
end

function misc.onlieHelp ()
    local text = ""
    text = text .. "You are running awesome <span fgcolor='red'>" .. awesome.version .. "</span> (<span fgcolor='red'>" .. awesome.release .. "</span>)"
    text = text .. "\n" .. "with config version <span fgcolor='red'>" .. rudiment.config.version .. "</span>"
    text = text .. "\n\n" .. "help can be found at the URL: <u>" .. rudiment.config.help_url .. "</u>"
    text = text .. "\n\n\n\n" .. "opening in <b>" .. rudiment.tools.browser.primary .. "</b>..."
    naughty.notify({
        preset = naughty.config.presets.normal,
        title="help about configuration",
        text=text,
        timeout = 20,
        screen = mouse.screen,
    })
    awful.util.spawn_with_shell(rudiment.tools.browser.primary .. " '" .. rudiment.config.help_url .. "'")
end

do
    -- randomly select a background picture
    --{{
    function misc.change_wallpaper()
        if rudiment.option.wallpaper_change_p then
            awful.util.spawn_with_shell("cd " .. rudiment.config_path .. "/wallpaper/; ./my-wallpaper-pick.sh")
        end
    end
    misc.timer.change_wallpaper= timer({timeout = rudiment.default.wallpaper_change_interval})

    misc.timer.change_wallpaper:connect_signal("timeout", misc.change_wallpaper)

    misc.timer.change_wallpaper:connect_signal("property::timeout",
    function ()
        misc.timer.change_wallpaper:stop()
        misc.timer.change_wallpaper:start()
    end
    )

    misc.timer.change_wallpaper:start()
    -- first trigger
    misc.change_wallpaper()
    --}}
end

-- {{{ Customized functions

misc.system_lock = function ()
  awful.util.spawn("xscreensaver-command -l")
end

misc.system_suspend = function ()
  awful.util.spawn("systemctl suspend")
end

misc.system_hibernate = function ()
  local scr = mouse.screen
  awful.prompt.run({prompt = "Hibernate (type 'yes' to confirm)? "},
  mypromptbox[scr].widget,
  function (t)
    if string.lower(t) == 'yes' then
      awful.util.spawn("systemctl hibernate")
    end
  end,
  function (t, p, n)
    return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
  end)
end

misc.system_hybrid_sleep = function ()
  local scr = mouse.screen
  awful.prompt.run({prompt = "Hybrid Sleep (type 'yes' to confirm)? "},
  mypromptbox[scr].widget,
  function (t)
    if string.lower(t) == 'yes' then
      awful.util.spawn("systemctl hybrid-sleep")
    end
  end,
  function (t, p, n)
    return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
  end)
end

misc.system_reboot = function ()
  local scr = mouse.screen
  awful.prompt.run({prompt = "Reboot (type 'yes' to confirm)? "},
  mypromptbox[scr].widget,
  function (t)
    if string.lower(t) == 'yes' then
      awful.util.spawn("systemctl reboot")
    end
  end,
  function (t, p, n)
    return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
  end)
end

misc.system_power_off = function ()
  local scr = mouse.screen
  awful.prompt.run({prompt = "Power Off (type 'yes' to confirm)? "},
  mypromptbox[scr].widget,
  function (t)
    if string.lower(t) == 'yes' then
      awful.util.spawn("systemctl poweroff")
    end
  end,
  function (t, p, n)
    return awful.completion.generic(t, p, n, {'no', 'NO', 'yes', 'YES'})
  end)
end

misc.app_finder = function ()
    awful.util.spawn("xfce4-appfinder")
end

-- {{ client actions

misc.client_focus_next = function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end

misc.client_focus_prev = function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end

misc.client_focus_next_n = function (n)
    awful.client.focus.byidx(n)
    if client.focus then client.focus:raise() end
end

misc.client_focus_urgent = awful.client.urgent.jumpto

misc.client_swap_next = function () awful.client.swap.byidx(  1) end

misc.client_swap_prev = function () awful.client.swap.byidx( -1) end

misc.client_move_next = function () util.client.rel_send(1) end

misc.client_move_prev = function () util.client.rel_send(-1) end

misc.client_move_to_tag = function ()
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
end

misc.client_toggle_tag = function (c)
  local keywords = {}
  local scr = mouse.screen
  for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
    table.insert(keywords, t.name)
  end
  local c = c or client.focus
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
end

misc.client_toggle_titlebar = function ()
  awful.titlebar.toggle(client.focus)
end

misc.client_raise = function (c)
  c:raise()
end

misc.client_fullscreen = function (c)
  c.fullscreen = not c.fullscreen
end

misc.client_maximize_horizontal = function (c)
  c.maximized_horizontal = not c.maximized_horizontal
end

misc.client_maximize_vertical = function (c)
  c.maximized_vertical = not c.maximized_vertical
end

misc.client_maximize = function (c)
  misc.client_maximize_horizontal(c)
  misc.client_maximize_vertical(c)
end

misc.client_minimize = function (c)
  c.minimized = not c.minimized
end

do

  -- closures for client_status
  -- client_status[client] = {sidelined = <boolean>, geometry= <client geometry>}
  local client_status = {}

  misc.client_sideline_left = function (c)
    local scr = screen[mouse.screen]
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

  misc.client_sideline_right = function (c)
    local scr = screen[mouse.screen]
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

  misc.client_sideline_top = function (c)
    local scr = screen[mouse.screen]
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

  misc.client_sideline_bottom = function (c)
    local scr = screen[mouse.screen]
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

  misc.client_sideline_extend_left = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.x/7)
    if delta ~= 0 then
      cg.x = cg.x - delta
      cg.width = cg.width + delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_extend_right = function (c)
    local cg = c:geometry()
    local workarea = screen[mouse.screen].workarea
    local rmargin = math.max( (workarea.x + workarea.width - cg.x - cg.width), 0)
    local delta = math.floor(rmargin/7)
    if delta ~= 0 then
      cg.width = cg.width + delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_extend_top = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.y/7)
    if delta ~= 0 then
      cg.y = cg.y - delta
      cg.height = cg.height + delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_extend_bottom = function (c)
    local cg = c:geometry()
    local workarea = screen[mouse.screen].workarea
    local bmargin = math.max( (workarea.y + workarea.height - cg.y - cg.height), 0)
    local delta = math.floor(bmargin/7)
    if delta ~= 0 then
      cg.height = cg.height + delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_extend_left_n = function (n, c)
    local cg = c:geometry()
      cg.x = cg.x - misc.resize_step * n
      cg.width = cg.width + misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_extend_right_n = function (n, c)
    local cg = c:geometry()
      cg.width = cg.width + misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_extend_top_n = function (n, c)
    local cg = c:geometry()
      cg.y = cg.y - misc.resize_step * n
      cg.height = cg.height + misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_extend_bottom_n = function (n, c)
    local cg = c:geometry()
      cg.height = cg.height + misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_shrink_left = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > 256 then
      cg.width = cg.width - delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_shrink_right = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > 256 then
      cg.x = cg.x + delta
      cg.width = cg.width - delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_shrink_top = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > 256 then
      cg.height = cg.height - delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_shrink_bottom = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > 256 then
      cg.y = cg.y + delta
      cg.height = cg.height - delta
      c:geometry(cg)
    end
  end

  misc.client_sideline_shrink_left_n = function (n,c)
    local cg = c:geometry()
      cg.width = cg.width - misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_shrink_right_n = function (n,c)
    local cg = c:geometry()
      cg.x = cg.x + misc.resize_step * n
      cg.width = cg.width - misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_shrink_top_n = function (n,c)
    local cg = c:geometry()
      cg.height = cg.height - misc.resize_step * n
      c:geometry(cg)
  end

  misc.client_sideline_shrink_bottom = function (n,c)
    local cg = c:geometry()
      cg.y = cg.y + misc.resize_step * n
      cg.height = cg.height - misc.resize_step * n
      c:geometry(cg)
  end
end


misc.client_opaque_less = function (c)
  local opacity = c.opacity - 0.1
  if opacity and opacity >= rudiment.default.property.min_opacity then
    c.opacity = opacity
  end
end

misc.client_opaque_more = function (c)
  local opacity = c.opacity + 0.1
  if opacity and opacity <= rudiment.default.property.max_opacity then
    c.opacity = opacity
  end
end

misc.client_opaque_less_n = function (n,c)
  local opacity = c.opacity - n * misc.opaque_step
  if opacity and opacity >= rudiment.default.property.min_opacity then
    c.opacity = opacity
  end
end

misc.client_opaque_more_n = function (n,c)
  local opacity = c.opacity + n * misc.opaque_step
  if opacity and opacity <= rudiment.default.property.max_opacity then
    c.opacity = opacity
  end
end

misc.client_opaque_off = function (c)
  awful.util.spawn_with_shell("pkill " .. rudiment.default.compmgr)
end

misc.client_opaque_on = function (c)
  awful.util.spawn_with_shell(rudiment.default.compmgr)
end

misc.client_swap_with_master = function (c)
  c:swap(awful.client.getmaster())
end

misc.client_toggle_top = function (c)
  c.ontop = not c.ontop
end

misc.client_toggle_sticky = function (c)
  c.sticky = not c.sticky
end

misc.client_kill = function (c)
  c:kill()
end


misc.client_action_menu = function (c)
  c = c or client.focus
  local menu = awful.menu({
    theme = {
      width = 200,
    },
    items = {
      { "&cancel", function () end },
      { "=== task action menu ===" },
      { "--- status ---" },
      {
        "&raise", function ()
          misc.client_raise(c)
        end
      },
      {
        "&top", function ()
          misc.client_toggle_top(c)
        end
      },
      {
        "&sticky", function ()
          misc.client_toggle_sticky(c)
        end
      },
      {
        "&kill", function ()
          misc.client_kill(c)
        end
      },
      {
        "toggle title&bar", function ()
          misc.client_toggle_titlebar(c)
        end
      },
      { "--- focus ---" },
      {
        "&next client", function ()
          misc.client_focus_next(c)
        end
      },
      {
        "&prev client", function ()
          misc.client_focus_prev(c)
        end
      },
      {
        "&urgent", function ()
          misc.client_focus_urgent(c)
        end
      },
      { "--- tag ---" },
      {
        "move to next tag", function ()
          misc.client_move_next(c)
        end
      },
      {
        "move to previous tag", function ()
          misc.client_move_prev(c)
        end
      },
      {
        "move to ta&g", function ()
          misc.client_move_to_tag(c)
        end
      },
      {
        "togg&le tag", function ()
          misc.client_toggle_tag(c)
        end
      },
      { "--- geometry ---" },
      {
        "&fullscreen", function ()
          misc.client_fullscreen(c)
        end
      },
      {
        "m&aximize", function ()
          misc.client_maximize(c)
        end
      },
      {
        "maximize h&orizontal", function ()
          misc.client_maximize_horizontal(c)
        end
      },
      {
        "maximize &vertical", function ()
          misc.client_maximize_vertical(c)
        end
      },
      {
        "m&inimize", function ()
          misc.client_minimize(c)
        end
      },
      {
        "move to left", function ()
          misc.client_sideline_left(c)
        end
      },
      {
        "move to right", function ()
          misc.client_sideline_right(c)
        end
      },
      {
        "move to top", function ()
          misc.client_sideline_top(c)
        end
      },
      {
        "move to bottom", function ()
          misc.client_sideline_bottom(c)
        end
      },
      {
        "extend left", function ()
          misc.client_sideline_extend_left(c)
        end
      },
      {
        "extend right", function ()
          misc.client_sideline_extend_right(c)
        end
      },
      {
        "extend top", function ()
          misc.client_sideline_extend_top(c)
        end
      },
      {
        "extend bottom", function ()
          misc.client_sideline_extend_bottom(c)
        end
      },
      {
        "shrink left", function ()
          misc.client_sideline_shrink_left(c)
        end
      },
      {
        "shrink right", function ()
          misc.client_sideline_shrink_right(c)
        end
      },
      {
        "shrink top", function ()
          misc.client_sideline_shrink_top(c)
        end
      },
      {
        "shrink bottom", function ()
          misc.client_sideline_shrink_bottom(c)
        end
      },
      { "--- opacity ---"},
      {
        "&less opaque", function ()
          misc.client_opaque_less(c)
        end
      },
      {
        "&more opaque", function ()
          misc.client_opaque_more(c)
        end
      },
      {
        "opacity off", function ()
          misc.client_opaque_off(c)
        end
      },
      {
        "opacity on", function ()
          misc.client_opaque_on(c)
        end
      },
      { "--- ordering ---"},
      {
        "swap with master", function ()
          misc.client_swap_with_master(c)
        end
      },
      {
        "swap with next", function ()
          misc.client_swap_next(c)
        end
      },
      {
        "swap with prev", function ()
          misc.client_swap_prev(c)
        end
      },
    }
  })
  menu:toggle({keygrabber=true})
end

-- }}

-- {{ tag actions

misc.tag_add_after = function ()
  local scr = mouse.screen
  local sel_idx = awful.tag.getidx()
  local t = util.tag.add(nil,
  {
    screen = scr,
    index = sel_idx and sel_idx+1 or 1,
    layout = rudiment.default.property.layout,
    mwfact = rudiment.default.property.mwfact,
    nmaster = rudiment.default.property.nmaster,
    ncol = rudiment.default.property.ncol,
  })
end

misc.tag_add_before = function ()
  local scr = mouse.screen
  local sel_idx = awful.tag.getidx()
  local t = util.tag.add(nil,
  {
    screen = scr,
    index = sel_idx and sel_idx or 1,
    layout = rudiment.default.property.layout,
    mwfact = rudiment.default.property.mwfact,
    nmaster = rudiment.default.property.nmaster,
    ncol = rudiment.default.property.ncol,
  })
end

misc.tag_delete = awful.tag.delete

misc.tag_rename = function ()
  local scr = mouse.screen
  local sel = awful.tag.selected(scr)
  util.tag.rename(sel)
end

misc.tag_view_prev = awful.tag.viewprev

misc.tag_view_next = awful.tag.viewnext

misc.tag_last = awful.tag.history.restore

misc.tag_goto = function ()
  local keywords = {}
  local scr = mouse.screen
  for _, t in ipairs(awful.tag.gettags(scr)) do -- only the current screen
    table.insert(keywords, t.name)
  end
  awful.prompt.run({prompt = "Goto tag: "},
  mypromptbox[scr].widget,
  function (t)
    awful.tag.viewonly(util.tag.name2tag(t))
  end,
  function (t, p, n)
    return awful.completion.generic(t, p, n, keywords)
  end)
end

misc.tag_move_forward = function () util.tag.rel_move(awful.tag.selected(), 1) end

misc.tag_move_backward = function () util.tag.rel_move(awful.tag.selected(), -1) end

misc.tag_action_menu = function (t)
  t = t or awful.tag.selected()
  if t then
    local menu = awful.menu({
      theme = {
        width = 200,
      },
      items = {
        { "&cancel", function () end },
        { "=== tag action menu ===" },
        { "--- dynamic tagging ---" },
        {
          "add tag &after current one", function ()
            misc.tag_add_after(t)
          end
        },
        {
          "add tag &before current one", function ()
            misc.tag_add_before(t)
          end
        },
        {
          "&delete current tag if empty", function ()
            misc.tag_delete(t)
          end
        },
        {
          "&rename current tag", function ()
            misc.tag_rename(t)
          end
        },
        { "--- focus ---" },
        {
          "&goto tag", function ()
            misc.tag_goto(t)
          end
        },
        {
          "view &previous tag", function ()
            misc.tag_view_prev(t)
          end
        },
        {
          "view &next tag", function ()
            misc.tag_view_next(t)
          end
        },
        {
          "view &last tag", function ()
            misc.tag_last(t)
          end
        },
        { "--- ordering ---" },
        {
          "move tag &forward", function ()
            misc.tag_move_forward()
          end
        },
        {
          "move tag &backward", function ()
            misc.tag_move_backward()
          end
        },
      }
    })
    menu:toggle({keygrabber=true})
  end
end

-- }}

-- {{ clients on tags

misc.clients_on_tag = function ()
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
            client.focus = c
            c:raise()
          end,
          c.icon
        })
      end
    end
    if next(clients.items) ~= nil then
      local m = awful.menu(clients)
      m:show({keygrabber=true})
      return m
    end
  end
end

misc.clients_on_tag_prompt = function ()
  local clients = {}
  local next = next
  local t = awful.tag.selected()
  if t then
    local keywords = {}
    local scr = mouse.screen
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
      mypromptbox[scr].widget,
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

misc.all_clients = function ()
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
          client.focus = c
          c:raise()
        end,
        c.icon
      })
    end
  end
  if next(clients.items) ~= nil then
    local m = awful.menu(clients)
    m:show({keygrabber=true})
    return m
  end
end

misc.all_clients_prompt = function ()
  local clients = {}
  local next = next
  local keywords = {}
  local scr = mouse.screen
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
    mypromptbox[scr].widget,
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

local awesome_restart_tags_fname = "/tmp/awesome-restart-tags-" .. os.getenv("XDG_SESSION_ID")
misc.client_manage_tag = function (c, startup)
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

function misc.util.compose(f, g)
    return
    function(...)
        return f(g(...))
    end
end

function misc.util.negate (n)
    return -n;
end

return misc
