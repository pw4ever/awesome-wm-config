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
local naughty = require("naughty")
local menubar = require("menubar")

-- bashets config: https://gitorious.org/bashets/pages/Brief_Introduction
local bashets = require("../bashets")

-- utilities
local util = require("../util")

local capi = {
    tag = tag,
    screen = screen,
    client = client,
}


-- customization
customization = {}
customization.config = {}
customization.orig = {}
customization.func = {}
customization.default = {}
customization.option = {}
customization.timer = {}


customization.default.property = {
    layout = awful.layout.suit.floating,
    mwfact = 0.5,
    nmaster = 1,
    ncol = 1,
    min_opacity = 0.01,
    max_opacity = 1,
    default_naughty_opacity = 0.90,
    low_naughty_opacity = 0.90,
    normal_naughty_opacity = 0.95,
    critical_naughty_opacity = 1,
}

customization.default.compmgr = 'xcompmgr'
customization.default.wallpaper_change_interval = 15

customization.option.wallpaper_change_p = true
customization.config_path = awful.util.getdir("config")

do
    -- randomly select a background picture
    --{{
    function customization.func.change_wallpaper()
        if customization.option.wallpaper_change_p then
            awful.util.spawn_with_shell("cd " .. customization.config_path .. "/wallpaper/; ./my-wallpaper-pick.sh")
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

-- {{{ Customized functions

customization.func.system_lock = function ()
  awful.util.spawn("xscreensaver-command -l")
end

customization.func.system_suspend = function ()
  awful.util.spawn("systemctl suspend")
end

customization.func.system_hibernate = function ()
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

customization.func.system_hybrid_sleep = function ()
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

customization.func.system_reboot = function ()
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

customization.func.system_power_off = function ()
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

customization.func.client_toggle_tag = function (c) 
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
  customization.func.client_maximize_horizontal(c)
  customization.func.client_maximize_vertical(c)
end

customization.func.client_minimize = function (c) 
  c.minimized = not c.minimized
end

do 

  -- closures for client_status
  -- client_status[client] = {sidelined = <boolean>, geometry= <client geometry>}
  local client_status = {}

  customization.func.client_sideline_left = function (c)
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

  customization.func.client_sideline_right = function (c)
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

  customization.func.client_sideline_top = function (c)
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

  customization.func.client_sideline_bottom = function (c)
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

  customization.func.client_sideline_extend_left = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.x/7)
    if delta ~= 0 then
      cg.x = cg.x - delta
      cg.width = cg.width + delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_extend_right = function (c)
    local cg = c:geometry()
    local workarea = screen[mouse.screen].workarea
    local rmargin = math.max( (workarea.x + workarea.width - cg.x - cg.width), 0)
    local delta = math.floor(rmargin/7)
    if delta ~= 0 then
      cg.width = cg.width + delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_extend_top = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.y/7)
    if delta ~= 0 then
      cg.y = cg.y - delta
      cg.height = cg.height + delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_extend_bottom = function (c)
    local cg = c:geometry()
    local workarea = screen[mouse.screen].workarea
    local bmargin = math.max( (workarea.y + workarea.height - cg.y - cg.height), 0)
    local delta = math.floor(bmargin/7)
    if delta ~= 0 then
      cg.height = cg.height + delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_shrink_left = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > 256 then
      cg.width = cg.width - delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_shrink_right = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.width/11)
    if delta ~= 0 and cg.width > 256 then
      cg.x = cg.x + delta
      cg.width = cg.width - delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_shrink_top = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > 256 then
      cg.height = cg.height - delta
      c:geometry(cg)
    end
  end

  customization.func.client_sideline_shrink_bottom = function (c)
    local cg = c:geometry()
    local delta = math.floor(cg.height/11)
    if delta ~= 0 and cg.height > 256 then
      cg.y = cg.y + delta
      cg.height = cg.height - delta
      c:geometry(cg)
    end
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
  awful.util.spawn_with_shell(customization.default.compmgr)
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


customization.func.client_action_menu = function (c)
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
          customization.func.client_raise(c)
        end
      },
      {
        "&top", function () 
          customization.func.client_toggle_top(c)
        end
      },
      {
        "&sticky", function () 
          customization.func.client_toggle_sticky(c)    
        end
      },
      {
        "&kill", function () 
          customization.func.client_kill(c)
        end
      },
      {
        "toggle title&bar", function () 
          customization.func.client_toggle_titlebar(c)
        end
      },
      { "--- focus ---" },
      {
        "&next client", function () 
          customization.func.client_focus_next(c)
        end
      },
      {
        "&prev client", function () 
          customization.func.client_focus_prev(c)
        end
      },
      {
        "&urgent", function () 
          customization.func.client_focus_urgent(c)
        end
      },
      { "--- tag ---" },
      {
        "move to next tag", function () 
          customization.func.client_move_next(c)
        end
      },
      {
        "move to previous tag", function () 
          customization.func.client_move_prev(c)
        end
      },
      {
        "move to ta&g", function () 
          customization.func.client_move_to_tag(c)
        end
      },
      {
        "togg&le tag", function () 
          customization.func.client_toggle_tag(c)
        end
      },
      { "--- geometry ---" },
      {
        "&fullscreen", function () 
          customization.func.client_fullscreen(c)
        end
      },
      {
        "m&aximize", function () 
          customization.func.client_maximize(c)
        end
      },
      {
        "maximize h&orizontal", function () 
          customization.func.client_maximize_horizontal(c)
        end
      },
      {
        "maximize &vertical", function () 
          customization.func.client_maximize_vertical(c)
        end
      },
      {
        "m&inimize", function () 
          customization.func.client_minimize(c) 
        end
      },
      {
        "move to left", function () 
          customization.func.client_sideline_left(c) 
        end
      },
      {
        "move to right", function () 
          customization.func.client_sideline_right(c) 
        end
      },
      {
        "move to top", function () 
          customization.func.client_sideline_top(c) 
        end
      },
      {
        "move to bottom", function () 
          customization.func.client_sideline_bottom(c) 
        end
      },
      {
        "extend left", function () 
          customization.func.client_sideline_extend_left(c) 
        end
      },
      {
        "extend right", function () 
          customization.func.client_sideline_extend_right(c) 
        end
      },
      {
        "extend top", function () 
          customization.func.client_sideline_extend_top(c) 
        end
      },
      {
        "extend bottom", function () 
          customization.func.client_sideline_extend_bottom(c) 
        end
      },
      {
        "shrink left", function () 
          customization.func.client_sideline_shrink_left(c) 
        end
      },
      {
        "shrink right", function () 
          customization.func.client_sideline_shrink_right(c) 
        end
      },
      {
        "shrink top", function () 
          customization.func.client_sideline_shrink_top(c) 
        end
      },
      {
        "shrink bottom", function () 
          customization.func.client_sideline_shrink_bottom(c) 
        end
      },
      { "--- opacity ---"},
      {
        "&less opaque", function () 
          customization.func.client_opaque_less(c)
        end
      },
      {
        "&more opaque", function () 
          customization.func.client_opaque_more(c)
        end
      },
      {
        "opacity off", function () 
          customization.func.client_opaque_off(c)
        end
      },
      {
        "opacity on", function () 
          customization.func.client_opaque_on(c)
        end
      },
      { "--- ordering ---"},
      {
        "swap with master", function () 
          customization.func.client_swap_with_master(c)
        end
      },
      {
        "swap with next", function () 
          customization.func.client_swap_next(c)
        end
      },
      {
        "swap with prev", function () 
          customization.func.client_swap_prev(c)
        end
      },
    }
  })
  menu:toggle({keygrabber=true})
end

-- }}

-- {{ tag actions

customization.func.tag_add_after = function ()
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
end

customization.func.tag_add_before = function ()
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
end

customization.func.tag_delete = awful.tag.delete

customization.func.tag_rename = function ()
  local scr = mouse.screen
  local sel = awful.tag.selected(scr)
  util.tag.rename(sel)
end

customization.func.tag_view_prev = awful.tag.viewprev

customization.func.tag_view_next = awful.tag.viewnext

customization.func.tag_last = awful.tag.history.restore

customization.func.tag_goto = function () 
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

customization.func.tag_move_forward = function () util.tag.rel_move(awful.tag.selected(), 1) end

customization.func.tag_move_backward = function () util.tag.rel_move(awful.tag.selected(), -1) end

customization.func.tag_action_menu = function (t)
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
            customization.func.tag_add_after(t)
          end
        },
        {
          "add tag &before current one", function () 
            customization.func.tag_add_before(t)
          end
        },
        {
          "&delete current tag if empty", function () 
            customization.func.tag_delete(t)
          end
        },
        {
          "&rename current tag", function () 
            customization.func.tag_rename(t)
          end
        },
        { "--- focus ---" },
        {
          "&goto tag", function () 
            customization.func.tag_goto(t)
          end
        },
        {
          "view &previous tag", function () 
            customization.func.tag_view_prev(t)
          end
        },
        {
          "view &next tag", function () 
            customization.func.tag_view_next(t)
          end
        },
        {
          "view &last tag", function () 
            customization.func.tag_last(t)
          end
        },
        { "--- ordering ---" },
        {
          "move tag &forward", function () 
            customization.func.tag_move_forward()
          end
        },
        {
          "move tag &backward", function () 
            customization.func.tag_move_backward()
          end
        },
      }
    })
    menu:toggle({keygrabber=true})
  end
end

-- }}

-- {{ clients on tags

customization.func.clients_on_tag = function ()
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

customization.func.clients_on_tag_prompt = function () 
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

customization.func.all_clients = function ()
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

customization.func.all_clients_prompt = function ()
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

return customization
