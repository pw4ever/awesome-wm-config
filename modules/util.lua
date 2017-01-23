local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local capi = {
    client = client,
    tag = tag,
    screen = screen,
    button = button,
    mouse = mouse,
    root = root,
    timer = timer
}

local timer = require("gears.timer")

-- some of the routines are inspired by Shifty (https://github.com/bioe007/awesome-shifty.git)
local util = {}

-----
util.taglist = {}
util.taglist.taglist = {}

function util.taglist.set_taglist(taglist)
    util.taglist.taglist = taglist
end

-----
util.client = {}

function util.client.rel_send(rel_idx)
    local client = capi.client.focus
    local focused = awful.screen.focused()
    if client then 
        local scr = client.screen or focused.index
        local sel = focused.selected_tag
        local sel_idx = sel.index
        local tags = awful.tag.gettags(scr)
        local target = awful.util.cycle(#tags, sel_idx + rel_idx)
        awful.client.movetotag(tags[target], client)
        awful.tag.viewonly(tags[target])
    end
end


-----
util.tag = {}

function util.tag.rel_move(tag, rel_idx)
    if tag then 
        local scr = awful.tag.getscreen(tag)
        local tag_idx = awful.tag.getidx(tag)
        local tags = awful.tag.gettags(scr)
        local target = awful.util.cycle(#tags, tag_idx + rel_idx)
        awful.tag.move(target, tag)
        awful.tag.viewonly(tag)
    end
end

--name2tags: matches string 'name' to tag objects
--@param name: tag name to find
--@param scr: screen to look for tags on
--@return table of tag objects or nil
function util.tag.name2tags(name, scr)
    local ret = {}
    local a, b = scr or 1, scr or capi.screen.count()
    for s = a, b do
        for _, t in ipairs(awful.tag.gettags(s)) do
            if name == t.name then
                table.insert(ret, t)
            end
        end
    end
    if #ret > 0 then return ret end
end

function util.tag.name2tag(name, scr, idx)
    local ts = util.tag.name2tags(name, scr)
    if ts then return ts[idx or 1] end
end

--add: add a tag
--@param name: name of the tag
--@param props: table of properties (screen, index, etc.)
function util.tag.add(name, props)
    props = props or 
    { 
        screen = awful.screen.focused(),
        index = 1,
    }

    local t = awful.tag.add(name or " ", props)
    if t then
        t.index = props.index
        t.screen = props.screen
        t:view_only()
    end

    -- if add the tag interactively
    if not name then
        -- !!! awful.wdiget.taglist update logic mandates this
        -- !!! lib/awful/widget/taglist.lua: taglist.new > w._do_taglist_update()
        timer.delayed_call(function () util.tag.rename(t, true) end)
    end

    return t
end

--rename
--@param tag: tag object to be renamed
--@param newp: boolean; true if the tag is new
function util.tag.rename(tag, newp)
    local theme = beautiful.get()
    local t = tag
    if not t then return end
    local scr = t.screen or awful.screen.focused()
    if not scr then return end
    local bg = nil
    local fg = nil
    local text = t.name
    local before = t.name

    if t == scr.selected_tag then
        bg = theme.bg_focus or '#535d6c'
        fg = theme.fg_urgent or '#ffffff'
    else
        bg = theme.bg_normal or '#222222'
        fg = theme.fg_urgent or '#ffffff'
    end

    --debug -- used to probe internal structures of taglist widget
    --[[
    do
        local key = ""
        for k, _ in pairs(util.taglist.taglist[scr.index].children[t.index].widget.children[2].widget) do
            key = key .. "\n" .. k
        end
        naughty.notify(
        {
            text=key,
            timeout=300,
        }
        ) 
    end

    naughty.notify({text = "rename: " .. t.index .. " " .. #t.screen.tags .. " " .. #util.taglist.taglist[t.screen.index].children})
    --]]

    awful.prompt.run(
    {
        fg_cursor = fg,
        bg_cursor = bg,
        ul_cursor = "single",
        text = text,
        selectall = true
    },
    -- taglist internals -- found with the debug code above
    util.taglist.taglist[scr].children[t.index].widget.children[2].widget,
    function (name)
        if name:len() > 0 then
            t.name = name;
        end
    end,
    nil,
    nil,
    nil,
    function ()
        if t.name == before then
            if newp then
                t:delete()
            end
        else
            t:emit_signal("property::name")
        end
    end
    )
end

--pread
--@param cmd: string; Shell command whose output will be piped in.
function util.pread(cmd)
    local fp = io.popen(cmd, "r")
    local result = fp:read("*a")
    fp:close()
    return result
end

return util
