-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local io = io
local setmetatable = setmetatable
local tonumber = tonumber
local pairs = pairs
local lib = {
    widget = require("obvious.lib.widget")
}

module("obvious.io")

local function info(dev)
    local f = io.open("/proc/diskstats")
    local line

    if f == nil then
        return ret
    end

    line = f:read()

    while line and not line:match(dev) do
        line = f:read()
    end

    f:close()

    if not line then
        return nil
    end

    local ret = { }
    -- each time matches() is called it returns the next number from line
    local matches = line:gmatch("%d+")

    -- First two are device numbers, skip them
    matches()
    matches()

    ret.reads_completed  = tonumber(matches())
    ret.reads_merged     = tonumber(matches())
    ret.reads_sectors    = tonumber(matches())
    ret.reads_time_ms    = tonumber(matches())
    ret.writes_completed = tonumber(matches())
    ret.writes_merged    = tonumber(matches())
    ret.writes_sectors   = tonumber(matches())
    ret.writes_time_ms   = tonumber(matches())
    ret.in_progress      = tonumber(matches())
    ret.time_ms          = tonumber(matches())
    ret.time_ms_weight   = tonumber(matches())

    return ret
end

local function get_increase(data)
    local last = data.last
    local cur = info(data.device)

    if not cur then
        return nil
    end

    data.last = cur

    -- Fake for starting
    if last == nil then
        last = cur
    end

    local ret = { }
    for k, v in pairs(cur) do
        ret[k] = cur[k] - last[k]
    end

    return ret
end

local function get(data)
    local val = get_increase(data)
    if not val then
        return
    end
    return val.writes_sectors + val.reads_sectors
end

local function get_data_source(device)
    local device = device or "sda"
    local ret = {}

    ret.get = get
    ret.device = device

    return lib.widget.from_data_source(ret)
end

setmetatable(_M, { __call = function (_, ...) return get_data_source(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
