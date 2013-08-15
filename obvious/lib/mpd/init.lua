--
--  _                                       _
-- | |_   _  __ _       _ __ ___  _ __   __| |
-- | | | | |/ _` |_____| '_ ` _ \| '_ \ / _` |
-- | | |_| | (_| |_____| | | | | | |_) | (_| |
-- |_|\__,_|\__,_|     |_| |_| |_| .__/ \__,_|
--                               |_|
--
-- Small interface to MusicPD
-- use luasocket, with a persistant connection to the MPD server.
--
-- based on a netcat version from Steve Jothen <sjothen at gmail dot com>
-- (see http://modeemi.fi/~tuomov/repos/ion-scripts-3/scripts/mpd.lua)
--
--
-- Copyright (c) 2008-2009, Alexandre Perrin <kaworu@kaworu.ch>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 4. Neither the name of the author nor the names of its contributors
--    may be used to endorse or promote products derived from this software
--    without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.


-- Grab env
local have_socket, socket = pcall(function() return require("socket") end)
local string = string
local tonumber = tonumber
local setmetatable = setmetatable
local os = os

-- Music Player Daemon Lua library.
module("obvious.lib.mpd")

MPD = {
} MPD_mt = { __index = MPD }

-- create and return a new mpd client.
-- the settings argument is a table with theses keys:
--      hostname: the MPD's host (default localhost)
--      port:     MPD's port to connect to (default 6600)
--      desc:     server's description (default hostname)
--      password: the server's password (default nil, no password)
--      timeout:  time in sec to wait for connect() and receive() (default 1)
--      retry:    time in sec to wait before reconnect if error (default 60)
function new(settings)
    local client = {}
    if settings == nil then settings = {} end

    client.hostname = settings.hostname or "localhost"
    client.port     = settings.port or 6600
    client.desc     = settings.desc or client.hostname
    client.password = settings.password
    client.timeout  = settings.timeout or 1
    client.retry    = settings.retry or 60

    setmetatable(client, MPD_mt)

    return client
end


-- calls the action and returns the server's response.
--      Example: if the server's response to "status" action is:
--              volume: 20
--              repeat: 0
--              random: 0
--              playlist: 599
--              ...
--      then the returned table is:
--      { volume = 20, repeat = 0, random = 0, playlist = 599, ... }
--
-- if an error arise (bad password, connection failed etc.), a table with only
-- the errormsg field is returned.
--      Example: if there is no server running on host/port, then the returned
--      table is:
--              { errormsg = "could not connect" }
--
function MPD:send(action)
    local command = string.format("%s\n", action)
    local values = {}

    if not have_socket then
        return { errormsg = "could not require(\"socket\")" }
    end

    -- connect to MPD server if not already done.
    if not self.connected then
        local now = os.time();
        if not self.last_try or (now - self.last_try) > self.retry then
            self.socket = socket.tcp()
            self.socket:settimeout(self.timeout, 't')
            self.last_try = os.time()
            self.connected = self.socket:connect(self.hostname, self.port)
            if not self.connected then
                return { errormsg = "could not connect" }
            end

            -- Read the server's hello message
            local line = self.socket:receive("*l")
            if not line:match("^OK MPD") then -- Invalid hello message?
                self.connected = false
                return { errormsg = string.format("invalid hello message: %s", line) }
            end

            -- send the password if needed
            if self.password then
                local rsp = self:send(string.format("password %s", self.password))
                if rsp.errormsg then
                    return rsp
                end
            end
        else
            local retry_sec = self.retry - (now - self.last_try)
            return { errormsg = string.format("retrying connection in %d sec", retry_sec) }
        end
    end

    self.socket:send(command)

    local line = ""
    while not line:match("^OK$") do
        line = self.socket:receive("*l")
        if not line then -- closed,timeout (mpd killed?)
            self.connected = false
            return self:send(action)
        end

        if line:match("^ACK") then
            return { errormsg = line }
        end

        local _, _, key, value = string.find(line, "([^:]+):%s(.+)")
        if key then
            values[string.lower(key)] = value
        end
    end

    return values
end

function MPD:next()
    return self:send("next")
end

function MPD:previous()
    return self:send("previous")
end

function MPD:stop()
    return self:send("stop")
end

-- no need to check the new value, mpd will set the volume in [0,100]
function MPD:volume_up(delta)
    local stats = self:send("status")
    local new_volume = tonumber(stats.volume) + delta

    return self:send(string.format("setvol %d", new_volume))
end

function MPD:volume_down(delta)
    return self:volume_up(-delta)
end

function MPD:toggle_random()
    local stats = self:send("status")
    if tonumber(stats.random) == 0 then
        return self:send("random 1")
    else
        return self:send("random 0")
    end
end

function MPD:toggle_repeat()
    local stats = self:send("status")
    if tonumber(stats["repeat"]) == 0 then
        return self:send("repeat 1")
    else
        return self:send("repeat 0")
    end
end

function MPD:toggle_play()
    if self:send("status").state == "stop" then
        return self:send("play")
    else
        return self:send("pause")
    end
end

-- vim:filetype=lua:tabstop=8:shiftwidth=4:expandtab:
