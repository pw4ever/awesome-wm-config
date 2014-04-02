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

-- some of the routines are inspired by Shifty
local util = {}

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
-- @param name : tag name to find
-- @param scr : screen to look for tags on
-- @return table of tag objects or nil
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

return util
