-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local io = io
local tonumber = tonumber
local setmetatable = setmetatable
local lib = {
    widget = require("obvious.lib.widget")
}

module("obvious.mem")

local function mem_usage()
    local f = io.open("/proc/meminfo")
    local ret = { }

    for line in f:lines() do
        if line:match('^MemTotal:') then
            ret.total = tonumber(line:match('(%d+)'))
        elseif line:match('^MemFree:') then
            ret.free = tonumber(line:match('(%d+)'))
        elseif line:match('^Buffers:') then
            ret.bufs = tonumber(line:match('(%d+)'))
        elseif line:match('^Cached:') then
            ret.cached = tonumber(line:match('(%d+)'))
        elseif line:match('^SwapTotal:') then
            ret.swap_total = tonumber(line:match('(%d+)'))
        elseif line:match('^SwapFree:') then
            ret.swap_free = tonumber(line:match('(%d+)'))
        end
    end

    f:close()

    ret.avail = ret.free + ret.bufs + ret.cached
    ret.used = ret.total - ret.avail
    ret.perc = (100 / ret.total) * ret.used
    ret.perc_not_free = (100 / ret.total) * (ret.total - ret.free)

    ret.swap_used = ret.swap_total - ret.swap_free
    ret.swap_perc = (100 / ret.swap_total) * ret.swap_used

    -- The following values are returned:
    -- * total         Total Memory
    -- * free          Total free memory
    -- * bufs          Memory used for buffers
    -- * cached        Memory used for caches
    -- * avail         Memory not used by user space
    -- * used          Memory used by user space
    -- * perc          Percentage of memory used by user space
    -- * perc_not_free Percentage of memory which is not free (different from 100 - perc!)
    -- * swap_total    Total swap space
    -- * swap_free     Free swap space
    -- * swap_used     Used swap space
    -- * swap_perc     Percentage of swap space used

    return ret
end

local function get()
    return mem_usage().perc
end

local function get_data_source()
    local ret = {}

    ret.max = 100
    ret.get = get

    return lib.widget.from_data_source(ret)
end

setmetatable(_M, { __call = function (_, ...) return get_data_source(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
