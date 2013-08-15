-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-----------------------------------

local setmetatable = setmetatable
local io = io
local tonumber = tonumber
local lib = {
    widget = require("obvious.lib.widget")
}

module("obvious.net")

-- Returns the total traffic send/received on some interface
local function netinfo(interface)
    local net = io.open("/proc/net/dev")
    local ret = { }

    -- Init in case we don't find any matches
    ret.recv = 0
    ret.send = 0

    for line in net:lines() do
        if line:match("^%s+" .. interface) then
            ret.recv = tonumber(line:match(":%s*(%d+)"))
            ret.send = tonumber(line:match("(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+$"))
        end
    end
    net:close()
    return ret
end

local function get_data(object)
    local last = object.last
    local cur = netinfo(object.device)
    object.last = cur

    local ret = { }
    if last then
        ret.recv = cur.recv - last.recv
        ret.send = cur.send - last.send
    else
        ret.recv = 0
        ret.send = 0
    end

    -- This can happen e.g. when an interface is brought down and up again
    -- or when some counter overflows
    if ret.recv < 0 then
        ret.recv = 0
    end
    if ret.send < 0 then
        ret.send = 0
    end

    return ret
end

local function data(device, key)
    local device = device or "eth0"
    local ret = {}

    ret.device = device
    ret.get = function(obj)
        return get_data(obj)[key]
    end

    return lib.widget.from_data_source(ret)
end

function recv(device)
    return data(device, "recv")
end

function send(device)
    return data(device, "send")
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
