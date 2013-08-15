-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local io = io
local setmetatable = setmetatable
local pairs = pairs
local lib = {
    widget = require("obvious.lib.widget")
}

module("obvious.fs_usage")

-- This returns the percentage of used space on the given mountpoint
function fs(path)
    local df = io.popen("LC_ALL=C df -hP " .. path)
    local key
    local ret = nil

    if not df then
        return nil
    end

    for line in df:lines() do
        local mountpoint = line:match("%% ([-/%w]+)$")
        local dev = line:match("^[%w/-]+")
        local perc = line:match("(%d+)%%")

        if perc ~= nil and mountpoint ~= nil and dev ~= nil then
            ret = perc
        end
    end

    df:close()
    return ret
end

local function get(data)
    return fs(data.path)
end

local function get_data_source(path)
    local path = path or "/"
    local ret = {}

    ret.max = 100
    ret.get = get
    ret.path = path

    return lib.widget.from_data_source(ret)
end

setmetatable(_M, { __call = function (_, ...) return get_data_source(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
