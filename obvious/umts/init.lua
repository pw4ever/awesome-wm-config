--
-- Track indicators from F3705 gadget.
--

------------------------------------------------------------------------------
-- "THE BEER-WARE LICENSE" (Revision 42):
-- <philip@paeps.cx> wrote this file. As long as you retain this notice you
-- can do whatever you want with this stuff. If we meet some day, and you
-- think this stuff is worth it, you can buy me a beer in return.
--                                                              - Philip Paeps
------------------------------------------------------------------------------

local assert = assert
local setmetatable = setmetatable
local io = {
    open = io.open
}
local capi = {
	widget = widget,
	mouse = mouse
}

local naughty = require("naughty")
local awful = require("awful")
local wibox = require("wibox")

local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.umts")

widget = wibox.widget.textbox()

local fh = nil
local cops = {}
local cind = {}

function wait_for_data(input)
	fh:write(input)
	local data = ""
	local lastline
	repeat
	    lastline = assert(fh:read())
	    data = data .. lastline .. "\n"
	until lastline:match("OK")
	return data
end

function get_indicators()
	local cind = wait_for_data("AT+CIND?\r\n")
	local rv = {}
	rv.signal = cind:match("+CIND: %d,(%d)")
	rv.service = cind:match("+CIND: %d,%d,%d,%d,(%d)")
	rv.roaming = cind:match("+CIND: %d,%d,%d,%d,%d,%d,%d,(%d)")
	return rv
end

function get_operator()
	wait_for_data("AT+COPS=3,0\r\n")
	local cops = wait_for_data("AT+COPS?\r\n")
	local rv = {}
	rv.mode = cops:match("+COPS: (%d)")
	rv.format = cops:match("+COPS: %d,(%d)")
	rv.oper = cops:match("+COPS: %d,%d,\"(%a*)\"")
	rv.act = cops:match("+COPS: %d,%d,\"%a*\",(%d)")
	return rv
end

local function update()
	fh = io.open("/dev/ttyACM1", "r+")
	if not fh then
	    cops = {}
	    cind = {}
	    widget.text = ""
	    return
	end

	cops = get_operator()
	cind = get_indicators()
	widget.text = " " .. cops.oper
	fh:close()
end

local function detail()
	if not cops.oper then return end

	naughty.notify({
	    text = "Mobile operator: " .. cops.oper ..
		"\nSignal strength: " .. cind.signal .. "/5" ..
		"\nRoaming: " .. cind.roaming,
	    screen = capi.mouse.screen
	})
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, detail)
))

update()
lib.hooks.timer.register(60, 300, update)
lib.hooks.timer.start(update)

setmetatable(_M, { __call = function () return widget end })
