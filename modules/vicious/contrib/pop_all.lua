-- contrib/pop_all.lua
-- Copyright (c) 2010  Boris Bolgradov
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
-- This widget type depends on luasocket.
--
-- Widget arguments are host, port, username and
-- password, i.e.:
--    {"mail.myhost.com", 110, "John", "132435"}
---------------------------------------------------

-- {{{ Grab environment
local tonumber = tonumber
local setmetatable = setmetatable
local sock_avail, socket = pcall(function()
    return require("socket")
end)
-- }}}


-- POP: provides the count of new messages in a POP3 mailbox
-- vicious.contrib.pop
local pop_all = {}


-- {{{ POP3 count widget type
local function worker(format, warg)
    if not sock_avail or (not warg or #warg ~= 4) then
        return {"N/A"}
    end

    local host, port = warg[1], tonumber(warg[2])
    local user, pass = warg[3], warg[4]

    local client = socket.tcp()
    client:settimeout(3)
    client:connect(host, port)
    client:receive("*l")
    client:send("USER " .. user .. "\r\n")
    client:receive("*l")
    client:send("PASS " .. pass .. "\r\n")
    client:receive("*l")
    client:send("STAT" .. "\r\n")
    local response = client:receive("*l")
    client:close()

    if response:find("%+OK") then
        response = response:match("%+OK (%d+)")
    end

    return {response}
end
-- }}}

return setmetatable(pop_all, { __call = function(_, ...) return worker(...) end })
