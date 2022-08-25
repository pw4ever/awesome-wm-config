-- contrib/pulse_all.lua
-- Copyright (C) 2010  MrMagne <mr.magne@yahoo.fr>
-- Copyright (C) 2010,2017  Jörg Thalheim <joerg@higgsboson.tk>
-- Copyright (C) 2017  Jonathan McCrohan <jmccrohan@gmail.com>
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

-- {{{ Grab environment
local type = type
local tonumber = tonumber
local io = { popen = io.popen }
local setmetatable = setmetatable
local os = { execute = os.execute }
local table = { insert = table.insert }
local string = {
    find = string.find,
    match = string.match,
    format = string.format,
    gmatch = string.gmatch
}
local math = {
    floor = math.floor,
    ceil = math.ceil
}
-- }}}


-- Pulse: provides volume levels of requested pulseaudio sinks and methods to change them
-- vicious.contrib.pulse
local pulse_all = {}

-- {{{ Helper function
local function pacmd(args)
    local f = io.popen("pacmd "..args)
    if f == nil then
      return nil
    else
      local line = f:read("*all")
      f:close()
      return line
    end
end

local function escape(text)
    local special_chars = { ["."] = "%.", ["-"] = "%-" }
    return text:gsub("[%.%-]", special_chars)
end

local cached_sinks = {}
local function get_sink_name(sink)
    if type(sink) == "string" then return sink end
    -- avoid nil keys
    local key = sink or 1
    -- Cache requests
    if not cached_sinks[key] then
      local line = pacmd("list-sinks")
      if line == nil then return nil end
      for s in string.gmatch(line, "name: <(.-)>") do
          table.insert(cached_sinks, s)
      end
    end

    return cached_sinks[key]
end


-- }}}

-- {{{ Pulseaudio widget type
local function worker(format, sink)
    sink = get_sink_name(sink)
    if sink == nil then return {0, "unknown"} end

    -- Get sink data
    local data = pacmd("dump")
    if sink == nil then return {0, "unknown"} end

    -- If mute return 0 (not "Mute") so we don't break progressbars
    if string.find(data,"set%-sink%-mute "..escape(sink).." yes") then
        return {0, "off"}
    end

    local vol = tonumber(string.match(data, "set%-sink%-volume "..escape(sink).." (0x[%x]+)"))
    if vol == nil then vol = 0 end
    volpercent = vol/0x10000*100

    return { volpercent % 1 >= 0.5 and math.ceil(volpercent) or math.floor(volpercent), "on"}
end
-- }}}

-- {{{ Volume control helper
function pulse_all.add(percent, sink)
    sink = get_sink_name(sink)
    if sink == nil then return end

    local data = pacmd("dump")

    local pattern = "set%-sink%-volume "..escape(sink).." (0x[%x]+)"
    local initial_vol =  tonumber(string.match(data, pattern))

    local vol = initial_vol + percent/100*0x10000
    if vol > 0x10000 then vol = 0x10000 end
    if vol < 0 then vol = 0 end

    vol = math.ceil(vol)

    local cmd = string.format("pacmd set-sink-volume %s 0x%x >/dev/null", sink, vol)
    return os.execute(cmd)
end

function pulse_all.toggle(sink)
    sink = get_sink_name(sink)
    if sink == nil then return end

    local data = pacmd("dump")
    local pattern = "set%-sink%-mute "..escape(sink).." (%a%a%a?)"
    local mute = string.match(data, pattern)

    -- 0 to enable a sink or 1 to mute it.
    local state = { yes = 0, no = 1}
    local cmd = string.format("pacmd set-sink-mute %s %d", sink, state[mute])
    return os.execute(cmd)
end
-- }}}

return setmetatable(pulse_all, { __call = function(_, ...) return worker(...) end })
