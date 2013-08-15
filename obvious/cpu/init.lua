-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local io = io
local tonumber = tonumber
local pairs = pairs
local setmetatable = setmetatable
local lib = {
    widget = require("obvious.lib.widget")
}

module("obvious.cpu")

local function cpu_info()
    local f = io.open("/proc/stat")
    local line = f:read()
    local ret = { }
    local matches = line:gmatch("%d+")

    f:close()

    -- each time matches() is called it returns the next number from line
    ret.user    = tonumber(matches())
    ret.nice    = tonumber(matches())
    ret.system  = tonumber(matches())
    ret.idle    = tonumber(matches())
    ret.iowait  = tonumber(matches())
    ret.irq     = tonumber(matches())
    ret.softirq = tonumber(matches())

    -- The returned array contains numbers which describe the time in number of
    -- jiffies since this box was started
    return ret
end

local function cpu_usage(object)
    local last = object.cpu_last
    local cur = cpu_info()
    object.cpu_last = cur

    -- Fake for starting
    if last == nil then
        last = cur
    end

    local ret = { }
    for k, v in pairs(cur) do
        ret[k] = cur[k] - last[k]
    end

    -- Calculate the cpu usage in percent
    -- Ignore iowait (dunno...)
    local t = ret.user + ret.nice + ret.system + ret.irq + ret.softirq
    if (t + ret.idle) == 0 then
        ret.perc = 0
    else
        ret.perc = 100 * t / (t + ret.idle)
    end

    -- This array now got the following keys (time is in jiffies!):
    -- * user    user cpu time
    -- * nice    cpu time for nice'd processes
    -- * system  cpu time spent in syscalls
    -- * idle    cpu time spent idlying
    -- * iowait  cpu time spent waiting for I/O
    -- * irq     cpu time spent in irq handlers
    -- * softirq cpu time spent in soft irq handlers
    -- * perc    percentage of time spent doing stuff
    return ret
end

local function get_data_source()
    local ret = {}

    ret.max = 100
    ret.get = function(obj)
        return cpu_usage(obj).perc
    end

    return lib.widget.from_data_source(ret)
end

setmetatable(_M, { __call = function (_, ...) return get_data_source(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
