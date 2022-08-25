-- contrib/rss_all.lua
-- Copyright (C) 2009  olcc
-- Copyright (C) 2017  Jörg Thalheim <joerg@higgsboson.tk>
--
-- This file is part of Vicious.
--
-- Vicious is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as
-- published by the Free Software Foundation, either version 2 of the
-- License, or (at your option) any later version.
--
-- Vicious is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Vicious.  If not, see <https://www.gnu.org/licenses/>.

---------------------------------------------------
-- This is now a standalone RSS reader for awesome:
--  * http://github.com/olcc/aware
---------------------------------------------------

-- {{{ Grab environment
local pairs = pairs
local io = { popen = io.popen }
local setmetatable = setmetatable
-- }}}


-- RSS: provides latest world news
-- vicious.contrib.rss
local rss_all = {}


-- {{{ RSS widget type
local function worker(format, input)
    -- input:  * feed   - feed url
    --         * object - entity to look for (typically: 'item')
    --         * fields - fields to read (example: 'link', 'title', 'description')
    -- output: * count  - number of entities found
    --         * one table for each field, containing wanted values
    local feed   = input.feed
    local object = input.object
    local fields = input.fields

    -- Initialise tables
    local out = {}

    for _, v in pairs(fields) do
        out[v] = {}
    end

    -- Initialise variables
    local ob    = nil
    local i,j,k = 1, 1, 0
    local curl  = "curl -A 'Mozilla/4.0' -fsm 5 --connect-timeout 3 "

    -- Get the feed
    local f = io.popen(curl .. '"' .. feed .. '"')
    local feed = f:read("*all")
    f:close()

    while true do
        i, j, ob = feed.find(feed, "<" .. object .. ">(.-)</" .. object .. ">", i)
        if not ob then break end

        for _, v in pairs(fields) do
            out[v][k] = ob:match("<" .. v .. ">(.*)</" .. v .. ">")
        end

        k = k+1
        i = j+1
    end

    -- Update the entity count
    out.count = k

    return out
end
-- }}}

return setmetatable(rss_all, { __call = function(_, ...) return worker(...) end })
