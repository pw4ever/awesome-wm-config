--- Shifty: Dynamic tagging library, version for awesome v3.5
-- @author koniu &lt;gkusnierz@gmail.com&gt;
-- @author resixian (aka bioe007) &lt;resixian@gmail.com&gt;
-- @author cdump &lt;andreevmaxim@gmail.com&gt;
--
-- https://github.com/cdump/awesome-shifty
-- http://awesome.naquadah.org/wiki/index.php?title=Shifty

-- environment
local type = type
local ipairs = ipairs
local table = table
local string = string
local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local pairs = pairs
local io = io
local tonumber = tonumber
local dbg= dbg
local capi = {
    client = client,
    tag = tag,
    screen = screen,
    button = button,
    mouse = mouse,
    root = root,
    timer = timer
}

local shifty = {}

-- variables
shifty.config = {}
shifty.config.tags = {}
shifty.config.apps = {}
shifty.config.defaults = {}
shifty.config.float_bars = false
shifty.config.guess_name = true
shifty.config.guess_position = true
shifty.config.remember_index = true
shifty.config.sloppy = true
shifty.config.default_name = "new"
shifty.config.clientkeys = {}
shifty.config.globalkeys = nil
shifty.config.layouts = {}
shifty.config.prompt_sources = {
    "config_tags",
    "config_apps",
    "existing",
    "history"
}
shifty.config.prompt_matchers = {
    "^",
    ":",
    ""
}
shifty.config.delete_deserted = true

local matchp = ""
local index_cache = {}
for i = 1, capi.screen.count() do index_cache[i] = {} end

--name2tags: matches string 'name' to tag objects
-- @param name : tag name to find
-- @param scr : screen to look for tags on
-- @return table of tag objects or nil
function name2tags(name, scr)
    local ret = {}
    local a, b = scr or 1, scr or capi.screen.count()
    for s = a, b do
        for i, t in ipairs(awful.tag.gettags(s)) do
            if name == t.name then
                table.insert(ret, t)
            end
        end
    end
    if #ret > 0 then return ret end
end

function name2tag(name, scr, idx)
    local ts = name2tags(name, scr)
    if ts then return ts[idx or 1] end
end

--tag2index: finds index of a tag object
-- @param scr : screen number to look for tag on
-- @param tag : the tag object to find
-- @return the index [or zero] or end of the list
function tag2index(scr, tag)
    for i, t in ipairs(awful.tag.gettags(scr)) do
        if t == tag then return i end
    end
end

--rename
--@param tag: tag object to be renamed
--@param prefix: if any prefix is to be added
--@param no_selectall:
function shifty.rename(tag, prefix, no_selectall)
    local theme = beautiful.get()
    local t = tag or awful.tag.selected(capi.mouse.screen)

    if t == nil then return end

    local scr = awful.tag.getscreen(t)
    local bg = nil
    local fg = nil
    local text = prefix or t.name
    local before = t.name

    if t == awful.tag.selected(scr) then
        bg = theme.bg_focus or '#535d6c'
        fg = theme.fg_urgent or '#ffffff'
    else
        bg = theme.bg_normal or '#222222'
        fg = theme.fg_urgent or '#ffffff'
    end
    
    local tag_index = tag2index(scr, t)
    -- Access to textbox widget in taglist
    local tb_widget = shifty.taglist[scr].widgets[tag_index].widget.widgets[2].widget
    awful.prompt.run({
        fg_cursor = fg, bg_cursor = bg, ul_cursor = "single",
        text = text, selectall = not no_selectall},
        tb_widget,
        function (name) if name:len() > 0 then t.name = name; end end,
        completion,
        awful.util.getdir("cache") .. "/history_tags",
        nil,
        function ()
            if t.name == before then
                if awful.tag.getproperty(t, "initial") then shifty.del(t) end
            else
                awful.tag.setproperty(t, "initial", true)
                set(t)
            end
            tagkeys(capi.screen[scr])
            t:emit_signal("property::name")
        end
        )
end

--send: moves client to tag[idx]
-- maybe this isn't needed here in shifty?
-- @param idx the tag number to send a client to
function send(idx)
    local scr = capi.client.focus.screen or capi.mouse.screen
    local sel = awful.tag.selected(scr)
    local sel_idx = tag2index(scr, sel)
    local tags = awful.tag.gettags(scr)
    local target = awful.util.cycle(#tags, sel_idx + idx)
    awful.client.movetotag(tags[target], capi.client.focus)
    awful.tag.viewonly(tags[target])
end

function shifty.send_next() send(1) end
function shifty.send_prev() send(-1) end

--pos2idx: translate shifty position to tag index
--@param pos: position (an integer)
--@param scr: screen number
function pos2idx(pos, scr)
    local v = 1
    if pos and scr then
        local tags = awful.tag.gettags(scr)
        for i = #tags , 1, -1 do
            local t = tags[i]
            if awful.tag.getproperty(t, "position") and
                awful.tag.getproperty(t, "position") <= pos then
                v = i + 1
                break
            end
        end
    end
    return v
end

--select : helper function chooses the first non-nil argument
--@param args - table of arguments
function select(args)
    for i, a in pairs(args) do
        if a ~= nil then
            return a
        end
    end
end

--tagtoscr : move an entire tag to another screen
--
--@param scr : the screen to move tag to
--@param t : the tag to be moved [awful.tag.selected()]
--@return the tag
function shifty.tagtoscr(scr, t)
    -- break if called with an invalid screen number
    if not scr or scr < 1 or scr > capi.screen.count() then return end
    -- tag to move
    local otag = t or awful.tag.selected()

    awful.tag.setscreen(otag, scr)
    -- set screen and then reset tag to order properly
    if #otag:clients() > 0 then
        for _ , c in ipairs(otag:clients()) do
            if not c.sticky then
                c.screen = scr
                c:tags({otag})
            else
                awful.client.toggletag(otag, c)
            end
        end
    end
    return otag
end

--set : set a tags properties
--@param t: the tag
--@param args : a table of optional (?) tag properties
--@return t - the tag object
function set(t, args)
    if not t then return end
    if not args then args = {} end

    -- set the name
    t.name = args.name or t.name

    -- attempt to load preset on initial run
    local preset = (awful.tag.getproperty(t, "initial") and
    shifty.config.tags[t.name]) or {}

    -- pick screen and get its tag table
    local scr = args.screen or
    (not awful.tag.getscreen(t) and awful.tag.getscreen(preset)) or
    awful.tag.getscreen(t) or
    capi.mouse.screen

    local clientstomove = nil
    if scr > capi.screen.count() then scr = capi.screen.count() end
    if awful.tag.getscreen(t) and scr ~= awful.tag.getscreen(t) then
        shifty.tagtoscr(scr, t)
        awful.tag.setscreen(t, nil)
    end
    local tags = awful.tag.gettags(scr)

    -- try to guess position from the name
    local guessed_position = nil
    if not (args.position or preset.position) and shifty.config.guess_position then
        local num = t.name:find('^[1-9]')
        if num then guessed_position = tonumber(t.name:sub(1, 1)) end
    end

    -- allow preset.layout to be a table to provide a different layout per
    -- screen for a given tag
    local preset_layout = preset.layout
    if preset_layout and preset_layout[scr] then
        preset_layout = preset.layout[scr]
    end

    -- select from args, preset, getproperty,
    -- config.defaults.configs or defaults
    local props = {
        layout = select{args.layout, preset_layout,
                        awful.tag.getproperty(t, "layout"),
                        shifty.config.defaults.layout, awful.layout.suit.tile},
        mwfact = select{args.mwfact, preset.mwfact,
                        awful.tag.getproperty(t, "mwfact"),
                        shifty.config.defaults.mwfact, 0.55},
        nmaster = select{args.nmaster, preset.nmaster,
                        awful.tag.getproperty(t, "nmaster"),
                        shifty.config.defaults.nmaster, 1},
        ncol = select{args.ncol, preset.ncol,
                        awful.tag.getproperty(t, "ncol"),
                        shifty.config.defaults.ncol, 1},
        matched = select{args.matched, awful.tag.getproperty(t, "matched")},
        exclusive = select{args.exclusive, preset.exclusive,
                        awful.tag.getproperty(t, "exclusive"),
                        shifty.config.defaults.exclusive},
        persist = select{args.persist, preset.persist,
                        awful.tag.getproperty(t, "persist"),
                        shifty.config.defaults.persist},
        nopopup = select{args.nopopup, preset.nopopup,
                        awful.tag.getproperty(t, "nopopup"),
                        shifty.config.defaults.nopopup},
        leave_kills = select{args.leave_kills, preset.leave_kills,
                        awful.tag.getproperty(t, "leave_kills"),
                        shifty.config.defaults.leave_kills},
        max_clients = select{args.max_clients, preset.max_clients,
                        awful.tag.getproperty(t, "max_clients"),
                        shifty.config.defaults.max_clients},
        position = select{args.position, preset.position, guessed_position,
                        awful.tag.getproperty(t, "position")},
        icon = select{args.icon and args.icon,
                        preset.icon and preset.icon,
                        awful.tag.getproperty(t, "icon"),
                    shifty.config.defaults.icon and shifty.config.defaults.icon},
        icon_only = select{args.icon_only, preset.icon_only,
                        awful.tag.getproperty(t, "icon_only"),
                        shifty.config.defaults.icon_only},
        sweep_delay = select{args.sweep_delay, preset.sweep_delay,
                        awful.tag.getproperty(t, "sweep_delay"),
                        shifty.config.defaults.sweep_delay},
        overload_keys = select{args.overload_keys, preset.overload_keys,
                        awful.tag.getproperty(t, "overload_keys"),
                        shifty.config.defaults.overload_keys},
    }

    -- get layout by name if given as string
    if type(props.layout) == "string" then
        props.layout = getlayout(props.layout)
    end

    -- set keys
    if args.keys or preset.keys then
        local keys = awful.util.table.join(shifty.config.globalkeys,
        args.keys or preset.keys)
        if props.overload_keys then
            props.keys = keys
        else
            props.keys = squash_keys(keys)
        end
    end

    -- calculate desired taglist index
    local index = args.index or preset.index or shifty.config.defaults.index
    local rel_index = args.rel_index or
    preset.rel_index or
    shifty.config.defaults.rel_index
    local sel = awful.tag.selected(scr)
    --TODO: what happens with rel_idx if no tags selected
    local sel_idx = (sel and tag2index(scr, sel)) or 0
    local t_idx = tag2index(scr, t)
    local limit = (not t_idx and #tags + 1) or #tags
    local idx = nil

    if rel_index then
        idx = awful.util.cycle(limit, (t_idx or sel_idx) + rel_index)
    elseif index then
        idx = awful.util.cycle(limit, index)
    elseif props.position then
        idx = pos2idx(props.position, scr)
        if t_idx and t_idx < idx then idx = idx - 1 end
    elseif shifty.config.remember_index and index_cache[scr][t.name] then
        idx = index_cache[scr][t.name]
    elseif not t_idx then
        idx = #tags + 1
    end

    -- if we have a new index, remove from old index and insert
    if idx then
        if t_idx then table.remove(tags, t_idx) end
        table.insert(tags, idx, t)
        index_cache[scr][t.name] = idx
    end

    -- set tag properties and push the new tag table
    for i, tmp_tag in ipairs(tags) do
        awful.tag.setproperty(tmp_tag, "index", i)
        awful.tag.setscreen(tmp_tag, scr)
    end
    for prop, val in pairs(props) do awful.tag.setproperty(t, prop, val) end

    -- execute run/spawn
    if awful.tag.getproperty(t, "initial") then
        local spawn = args.spawn or preset.spawn or shifty.config.defaults.spawn
        local run = args.run or preset.run or shifty.config.defaults.run
        if spawn and args.matched ~= true then
            awful.util.spawn_with_shell(spawn, scr)
        end
        if run then run(t) end
        awful.tag.setproperty(t, "initial", nil)
    end


    return t
end

function shift_next() set(awful.tag.selected(), {rel_index = 1}) end
function shift_prev() set(awful.tag.selected(), {rel_index = -1}) end

--add : adds a tag
--@param args: table of optional arguments
function shifty.add(args)
    if not args then args = {} end
    local name = args.name or " "

    -- initialize a new tag object and its data structure
    local t = awful.tag.add(name, { initial = true })


    -- apply tag settings
    set(t, args)

    -- unless forbidden or if first tag on the screen, show the tag
    if not (awful.tag.getproperty(t, "nopopup") or args.noswitch) or
        #awful.tag.gettags(awful.tag.getscreen(t)) == 1 then
        awful.tag.viewonly(t)
    end

    -- get the name or rename
    if args.name then
        t.name = args.name
    else
        -- FIXME: hack to delay rename for un-named tags for
        -- tackling taglist refresh which disabled prompt
        -- from being rendered until input
        awful.tag.setproperty(t, "initial", true)
        local f
        local tmr
        if args.position then
            f = function() shifty.rename(t, args.rename, true); tmr:stop() end
        else
            f = function() shifty.rename(t); tmr:stop() end
        end
        tmr = capi.timer({timeout = 0.01})
        tmr:connect_signal("timeout", f)
        tmr:start()
    end

    return t
end

--del : delete a tag
--@param tag : the tag to be deleted [current tag]
function shifty.del(tag)
    local scr = (tag and awful.tag.getscreen(tag)) or capi.mouse.screen or 1
    local tags = awful.tag.gettags(scr)
    local sel = awful.tag.selected(scr)
    local t = tag or sel
    local idx = tag2index(scr, t)

    -- return if tag not empty (except sticky)
    local clients = t:clients()
    local sticky = 0
    for i, c in ipairs(clients) do
        if c.sticky then sticky = sticky + 1 end
    end
    if #clients > sticky then return end

    -- store index for later
    index_cache[scr][t.name] = idx

    -- remove tag
    awful.tag.setscreen(t, nil)

    -- if the current tag is being deleted, restore from history
    if t == sel and #tags > 1 then
        awful.tag.history.restore(scr, 1)
        -- this is supposed to cycle if history is invalid?
        -- e.g. if many tags are deleted in a row
        if not awful.tag.selected(scr) then
            awful.tag.viewonly(tags[awful.util.cycle(#tags, idx - 1)])
        end
    end

    -- FIXME: what is this for??
    if capi.client.focus then capi.client.focus:raise() end
end

--is_client_tagged : replicate behavior in tag.c - returns true if the
--given client is tagged with the given tag
function is_client_tagged(tag, client)
    for i, c in ipairs(tag:clients()) do
        if c == client then
            return true
        end
    end
    return false
end

--match : handles app->tag matching, a replacement for the manage hook in
--            rc.lua
--@param c : client to be matched
function match(c, startup)
    local nopopup, intrusive, nofocus, run, slave
    local wfact, struts, geom, float
    local target_tag_names, target_tags = {}, {}
    local typ = c.type
    local cls = c.class
    local inst = c.instance
    local role = c.role
    local name = c.name
    local keys = shifty.config.clientkeys or c:keys() or {}
    local target_screen = capi.mouse.screen

    c.border_color = beautiful.border_normal
    c.border_width = beautiful.border_width

    -- try matching client to config.apps
    for i, a in ipairs(shifty.config.apps) do
        if a.match then
            local matched = false
            -- match only class
            if not matched and cls and a.match.class then
                for k, w in ipairs(a.match.class) do
                    matched = cls:find(w)
                    if matched then
                        break
                    end
                end
            end
            -- match only instance
            if not matched and inst and a.match.instance then
                for k, w in ipairs(a.match.instance) do
                    matched = inst:find(w)
                    if matched then
                        break
                    end
                end
            end
            -- match only name
            if not matched and name and a.match.name then
                for k, w in ipairs(a.match.name) do
                    matched = name:find(w)
                    if matched then
                        break
                    end
                end
            end
            -- match only role
            if not matched and role and a.match.role then
                for k, w in ipairs(a.match.role) do
                    matched = role:find(w)
                    if matched then
                        break
                    end
                end
            end
            -- match only type
            if not matched and typ and a.match.type then
                for k, w in ipairs(a.match.type) do
                    matched = typ:find(w)
                    if matched then
                        break
                    end
                end
            end
            -- check everything else against all attributes
            if not matched then
                for k, w in ipairs(a.match) do
                    matched = (cls and cls:find(w)) or
                            (inst and inst:find(w)) or
                            (name and name:find(w)) or
                            (role and role:find(w)) or
                            (typ and typ:find(w))
                    if matched then
                        break
                    end
                end
            end
            -- set attributes
            if matched then
                if a.screen then target_screen = a.screen end
                if a.tag then
                    if type(a.tag) == "string" then
                        target_tag_names = {a.tag}
                    else
                        target_tag_names = a.tag
                    end
                end
                if a.startup and startup then
                    a = awful.util.table.join(a, a.startup)
                end
                if a.geometry ~=nil then
                    geom = {x = a.geometry[1],
                    y = a.geometry[2],
                    width = a.geometry[3],
                    height = a.geometry[4]}
                end
                if a.float ~= nil then float = a.float end
                if a.slave ~=nil then slave = a.slave end
                if a.border_width ~= nil then
                    c.border_width = a.border_width
                end
                if a.nopopup ~=nil then nopopup = a.nopopup end
                if a.intrusive ~=nil then
                    intrusive = a.intrusive
                end
                if a.fullscreen ~=nil then
                    c.fullscreen = a.fullscreen
                end
                if a.honorsizehints ~=nil then
                    c.size_hints_honor = a.honorsizehints
                end
                if a.kill ~=nil then c:kill(); return end
                if a.ontop ~= nil then c.ontop = a.ontop end
                if a.above ~= nil then c.above = a.above end
                if a.below ~= nil then c.below = a.below end
                if a.buttons ~= nil then
                    c:buttons(a.buttons)
                end
                if a.nofocus ~= nil then nofocus = a.nofocus end
                if a.keys ~= nil then
                    keys = awful.util.table.join(keys, a.keys)
                end
                if a.hidden ~= nil then c.hidden = a.hidden end
                if a.minimized ~= nil then
                    c.minimized = a.minimized
                end
                if a.dockable ~= nil then
                    awful.client.dockable.set(c, a.dockable)
                end
                if a.urgent ~= nil then
                    c.urgent = a.urgent
                end
                if a.opacity ~= nil then
                    c.opacity = a.opacity
                end
                if a.run ~= nil then run = a.run end
                if a.sticky ~= nil then c.sticky = a.sticky end
                if a.wfact ~= nil then wfact = a.wfact end
                if a.struts then struts = a.struts end
                if a.skip_taskbar ~= nil then
                    c.skip_taskbar = a.skip_taskbar
                end
                if a.props then
                    for kk, vv in pairs(a.props) do
                        awful.client.property.set(c, kk, vv)
                    end
                end
            end
        end
    end

    -- set key bindings
    c:keys(keys)

    -- Add titlebars to all clients when the float, remove when they are
    -- tiled.
    if shifty.config.float_bars then
        shifty.create_titlebar(c)

        c:connect_signal("property::floating", function(c)
            if awful.client.floating.get(c) then
                awful.titlebar(c)
            else
                awful.titlebar(c, { size = 0 })
            end
            awful.placement.no_offscreen(c)
        end)
    end

    -- set properties of floating clients
    if float ~= nil then
        awful.client.floating.set(c, float)
        awful.placement.no_offscreen(c)
    end

    local sel = awful.tag.selectedlist(target_screen)
    if not target_tag_names or #target_tag_names == 0 then
        -- if not matched to some names try putting
        -- client in c.transient_for or current tags
        if c.transient_for then
            target_tags = c.transient_for:tags()
        elseif #sel > 0 then
            for i, t in ipairs(sel) do
                local mc = awful.tag.getproperty(t, "max_clients")
                if intrusive or
                    not (awful.tag.getproperty(t, "exclusive") or
                                    (mc and mc >= #t:clients())) then
                    table.insert(target_tags, t)
                end
            end
        end
    end

    if (not target_tag_names or #target_tag_names == 0) and
        (not target_tags or #target_tags == 0) then
        -- if we still don't know any target names/tags guess
        -- name from class or use default
        if shifty.config.guess_name and cls then
            target_tag_names = {cls:lower()}
        else
            target_tag_names = {shifty.config.default_name}
        end
    end

    if #target_tag_names > 0 and #target_tags == 0 then
        -- translate target names to tag objects, creating
        -- missing ones
        for i, tn in ipairs(target_tag_names) do
            local res = {}
            for j, t in ipairs(name2tags(tn, target_screen) or
                name2tags(tn) or {}) do
                local mc = awful.tag.getproperty(t, "max_clients")
                local tagged = is_client_tagged(t, c)
                if intrusive or
                    not (mc and (((#t:clients() >= mc) and not
                    tagged) or
                    (#t:clients() > mc))) or
                    intrusive then
                    if awful.tag.getscreen(t) == mouse.screen then
                        table.insert(res, t)
                    end
                end
            end
            if #res == 0 then
                table.insert(target_tags,
                shifty.add({name = tn,
                noswitch = true,
                matched = true}))
            else
                target_tags = awful.util.table.join(target_tags, res)
            end
        end
    end

    -- set client's screen/tag if needed
    target_screen = awful.tag.getscreen(target_tags[1]) or target_screen
    if c.screen ~= target_screen then c.screen = target_screen end
    if slave then awful.client.setslave(c) end
    c:tags(target_tags)

    if wfact then awful.client.setwfact(wfact, c) end
    if geom then c:geometry(geom) end
    if struts then c:struts(struts) end

    local showtags = {}
    local u = nil
    if #target_tags > 0 and not startup then
        -- switch or highlight
        for i, t in ipairs(target_tags) do
            if not (nopopup or awful.tag.getproperty(t, "nopopup")) then
                table.insert(showtags, t)
            elseif not startup then
                c.urgent = true
            end
        end
        if #showtags > 0 then
            local ident = false
            -- iterate selected tags and and see if any targets
            -- currently selected
            for kk, vv in pairs(showtags) do
                for _, tag in pairs(sel) do
                    if tag == vv then
                        ident = true
                    end
                end
            end
            if not ident then
                awful.tag.viewmore(showtags, c.screen)
            end
        end
    end

    if not (nofocus or c.hidden or c.minimized) then
        --focus and raise accordingly or lower if supressed
        if (target and target ~= sel) and
           (awful.tag.getproperty(target, "nopopup") or nopopup)  then
            awful.client.focus.history.add(c)
        else
            capi.client.focus = c
        end
        c:raise()
    else
        c:lower()
    end

    if shifty.config.sloppy then
        -- Enable sloppy focus
        c:connect_signal("mouse::enter", function(c)
            if awful.client.focus.filter(c) and
                awful.layout.get(c.screen) ~= awful.layout.suit.magnifier then
                capi.client.focus = c
            end
        end)
    end

    -- execute run function if specified
    if run then run(c, target) end

end

--sweep : hook function that marks tags as used, visited,
--deserted also handles deleting used and empty tags
function sweep()
    for s = 1, capi.screen.count() do
        for i, t in ipairs(awful.tag.gettags(s)) do
            local clients = t:clients()
            local sticky = 0
            for i, c in ipairs(clients) do
                if c.sticky then sticky = sticky + 1 end
            end
            if #clients == sticky then
                if awful.tag.getproperty(t, "used") and
                    not awful.tag.getproperty(t, "persist") then
                    if awful.tag.getproperty(t, "deserted") or
                        not awful.tag.getproperty(t, "leave_kills") then
                        local delay = awful.tag.getproperty(t, "sweep_delay")
                        if delay then
                            local tmr
                            local f = function()
                                        shifty.del(t); tmr:stop()
                                    end
                            tmr = capi.timer({timeout = delay})
                            tmr:connect_signal("timeout", f)
                            tmr:start()
                        else
                            if shifty.config.delete_deserted then
                                shifty.del(t)
                            end
                        end
                    else
                        if awful.tag.getproperty(t, "visited") and
                            not t.selected then
                            awful.tag.setproperty(t, "deserted", true)
                        end
                    end
                end
            else
                awful.tag.setproperty(t, "used", true)
            end
            if t.selected then
                awful.tag.setproperty(t, "visited", true)
            end
        end
    end
end

--getpos : returns a tag to match position
-- @param pos : the index to find
-- @return v : the tag (found or created) at position == 'pos'
function shifty.getpos(pos, scr_arg)
    local v = nil
    local existing = {}
    local selected = nil
    local scr = scr_arg or capi.mouse.screen or 1

    -- search for existing tag assigned to pos
    for i = 1, capi.screen.count() do
        for j, t in ipairs(awful.tag.gettags(i)) do
            if awful.tag.getproperty(t, "position") == pos then
                table.insert(existing, t)
                if t.selected and i == scr then
                    selected = #existing
                end
            end
        end
    end

    if #existing > 0 then
        -- if there is no selected tag on current screen, look for the first one
        if not selected then
            for _, tag in pairs(existing) do
                if awful.tag.getscreen(tag) == scr then return tag end
            end

            -- no tag found, loop through the other tags
            selected = #existing
        end

        -- look for the next unselected tag
        i = selected
        repeat
            i = awful.util.cycle(#existing, i + 1)
            tag = existing[i]

            if (scr_arg == nil or awful.tag.getscreen(tag) == scr_arg) and not tag.selected then return tag end
        until i == selected

        -- if the screen is not specified or
        -- if a selected tag exists on the specified screen
        -- return the selected tag
        if scr_arg == nil or awful.tag.getscreen(existing[selected]) == scr then return existing[selected] end

        -- if scr_arg ~= nil and no tag exists on this screen, continue
    end

    local screens = {}
    for s = 1, capi.screen.count() do table.insert(screens, s) end

    -- search for preconf with 'pos' on current screen and create it
    for i, j in pairs(shifty.config.tags) do
        local tag_scr = j.screen or screens
        if type(tag_scr) ~= 'table' then tag_scr = {tag_scr} end

        if j.position == pos and awful.util.table.hasitem(tag_scr, scr) then
            return shifty.add({name = i,
                    position = pos,
                    noswitch = not switch})
        end
    end

    -- not existing, not preconfigured
    return shifty.add({position = pos,
            rename = pos .. ':',
            no_selectall = true,
            noswitch = not switch})
end

--init : search config.tags for initial set of
--tags to open
function shifty.init()
    local numscr = capi.screen.count()

    local screens = {}
    for s = 1, capi.screen.count() do table.insert(screens, s) end

    for i, j in pairs(shifty.config.tags) do
        local scr = j.screen or screens
        if type(scr) ~= 'table' then
            scr = {scr}
        end
        for _, s in pairs(scr) do
            if j.init and (s <= numscr) then
                shifty.add({name = i,
                    persist = true,
                    screen = s,
                    layout = j.layout,
                    mwfact = j.mwfact})
            end
        end
    end
end

-- Create a titlebar for the given client
-- By default, make it invisible (size = 0)

function shifty.create_titlebar(c)
    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(awful.titlebar.widget.iconwidget(c))

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(awful.titlebar.widget.floatingbutton(c))
    right_layout:add(awful.titlebar.widget.maximizedbutton(c))
    right_layout:add(awful.titlebar.widget.stickybutton(c))
    right_layout:add(awful.titlebar.widget.ontopbutton(c))
    right_layout:add(awful.titlebar.widget.closebutton(c))

    -- The title goes in the middle
    local title = awful.titlebar.widget.titlewidget(c)
    title:buttons(awful.util.table.join(
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
            ))

    -- Now bring it all together
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)
    layout:set_middle(title)

    awful.titlebar(c, { size = 0 }):set_widget(layout)
end

--count : utility function returns the index of a table element
--FIXME: this is currently used only in remove_dup, so is it really
--necessary?
function count(table, element)
    local v = 0
    for i, e in pairs(table) do
        if element == e then v = v + 1 end
    end
    return v
end

--remove_dup : used by shifty.completion when more than one
--tag at a position exists
function remove_dup(table)
    local v = {}
    for i, entry in ipairs(table) do
        if count(v, entry) == 0 then v[#v+ 1] = entry end
    end
    return v
end

--completion : prompt completion
--
function completion(cmd, cur_pos, ncomp, sources, matchers)

    -- get sources and matches tables
    sources = sources or shifty.config.prompt_sources
    matchers = matchers or shifty.config.prompt_matchers

    local get_source = {
        -- gather names from config.tags
        config_tags = function()
            local ret = {}
            for n, p in pairs(shifty.config.tags) do
                table.insert(ret, n)
            end
            return ret
        end,
        -- gather names from config.apps
        config_apps = function()
            local ret = {}
            for i, p in pairs(shifty.config.apps) do
                if p.tag then
                    if type(p.tag) == "string" then
                        table.insert(ret, p.tag)
                    else
                        ret = awful.util.table.join(ret, p.tag)
                    end
                end
            end
            return ret
        end,
        -- gather names from existing tags, starting with the
        -- current screen
        existing = function()
            local ret = {}
            for i = 1, capi.screen.count() do
                local s = awful.util.cycle(capi.screen.count(),
                                            capi.mouse.screen + i - 1)
                local tags = awful.tag.gettags(s)
                for j, t in pairs(tags) do
                    table.insert(ret, t.name)
                end
            end
            return ret
        end,
        -- gather names from history
        history = function()
            local ret = {}
            local f = io.open(awful.util.getdir("cache") ..
                                    "/history_tags")
            for name in f:lines() do table.insert(ret, name) end
            f:close()
            return ret
        end,
    }

    -- if empty, match all
    if #cmd == 0 or cmd == " " then cmd = "" end

    -- match all up to the cursor if moved or no matchphrase
    if matchp == "" or
        cmd:sub(cur_pos, cur_pos+#matchp) ~= matchp then
        matchp = cmd:sub(1, cur_pos)
    end

    -- find matching commands
    local matches = {}
    for i, src in ipairs(sources) do
        local source = get_source[src]()
        for j, matcher in ipairs(matchers) do
            for k, name in ipairs(source) do
                if name:find(matcher .. matchp) then
                    table.insert(matches, name)
                end
            end
        end
    end

    -- no matches
    if #matches == 0 then return cmd, cur_pos end

    -- remove duplicates
    matches = remove_dup(matches)

    -- cycle
    while ncomp > #matches do ncomp = ncomp - #matches end

    -- put cursor at the end of the matched phrase
    if #matches == 1 then
        cur_pos = #matches[ncomp] + 1
    else
        cur_pos = matches[ncomp]:find(matchp) + #matchp
    end

    -- return match and position
    return matches[ncomp], cur_pos
end

-- tagkeys : hook function that sets keybindings per tag
function tagkeys(s)
    local sel = awful.tag.selected(s.index)
    local keys = awful.tag.getproperty(sel, "keys") or
                    shifty.config.globalkeys
    if keys and sel.selected then capi.root.keys(keys) end
end

-- squash_keys: helper function which removes duplicate
-- keybindings by picking only the last one to be listed in keys
-- table arg
function squash_keys(keys)
    local squashed = {}
    local ret = {}
    for i, k in ipairs(keys) do
        squashed[table.concat(k.modifiers) .. k.key] = k
    end
    for i, k in pairs(squashed) do
        table.insert(ret, k)
    end
    return ret
end

-- getlayout: returns a layout by name
function getlayout(name)
    for _, layout in ipairs(shifty.config.layouts) do
        if awful.layout.getname(layout) == name then
            return layout
        end
    end
end

-- add signals before using them
-- Note: these signals are emitted when tag properties
-- are accessed through awful.tag.setproperty
capi.tag.add_signal("property::initial")
capi.tag.add_signal("property::used")
capi.tag.add_signal("property::visited")
capi.tag.add_signal("property::deserted")
capi.tag.add_signal("property::matched")
capi.tag.add_signal("property::selected")
capi.tag.add_signal("property::position")
capi.tag.add_signal("property::exclusive")
capi.tag.add_signal("property::persist")
capi.tag.add_signal("property::index")
capi.tag.add_signal("property::nopopup")
capi.tag.add_signal("property::leave_kills")
capi.tag.add_signal("property::max_clients")
capi.tag.add_signal("property::icon_only")
capi.tag.add_signal("property::sweep_delay")
capi.tag.add_signal("property::overload_keys")

-- replace awful's default hook
capi.client.connect_signal("manage", match)
capi.client.connect_signal("unmanage", sweep)
capi.client.disconnect_signal("manage", awful.tag.withcurrent)

for s = 1, capi.screen.count() do
    awful.tag.attached_connect_signal(s, "property::selected", sweep)
    awful.tag.attached_connect_signal(s, "tagged", sweep)
    capi.screen[s]:connect_signal("tag::history::update", tagkeys)
end

return shifty

