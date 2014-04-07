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
    if client then 
        local scr = capi.client.focus.screen or capi.mouse.screen
        local sel = awful.tag.selected(scr)
        local sel_idx = awful.tag.getidx(sel)
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
        screen = capi.mouse.screen,
        index = 1,
    }

    local t = awful.tag.add(name or " ", props)
    if t then
        awful.tag.setscreen(t, props.screen)
        awful.tag.move(props.index or 1, t)
        awful.tag.viewonly(t)
    end

    -- if add the tag interactively
    if not name then
        util.tag.rename(t, true)
    end

    return t
end

--rename
--@param tag: tag object to be renamed
--@param newp: boolean; true if the tag is new
function util.tag.rename(tag, newp)
    local theme = beautiful.get()
    local t = tag or awful.tag.selected(capi.mouse.screen)
    if not t then return end
    local scr = t.screen or capi.mouse.screen
    if not scr then return end
    local bg = nil
    local fg = nil
    local text = t.name
    local before = t.name

    if t == awful.tag.selected(scr) then
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
        for k, _ in pairs(util.taglist.taglist[scr].widgets[awful.tag.getidx(t)].widget.widgets[2].widget) do
            key = key .. "\n" .. k
        end
        naughty.notify(
        {
            title=scr,
            text=key,
            timeout=20,
        }
        ) 
    end
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
    util.taglist.taglist[scr].widgets[awful.tag.getidx(t)].widget.widgets[2].widget,
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
                awful.tag.delete(t)
            end
        else
            t:emit_signal("property::name")
        end
    end
    )
end

return util
