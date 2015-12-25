------------------------------------------------------------------------
-- Bashets - use your shellscript's output in Awesome3 widgets
--
-- @author Anton Lobov &lt;ahmad200512@yandex.ru&gt;
-- @copyright 2010-2012 Anton Lobov
--
-- @contributor Victor Unegbu (fixed issue with formatting)
--
-- @license GPLv3
-- @release 0.6.3 
------------------------------------------------------------------------

-- Grab only needed enviroment
local awful = require("awful")
local string = string
local io = io
local table = table
local pairs = pairs
local timer = timer
local type = type
local image = image
local capi = {oocairo = oocairo, timer = timer, dbus = dbus}
local tonumber = tonumber
local print = print
local error = error

--- Bashets module
local bashets = {}

-- Default paths
local script_path = "/usr/share/awesome/bashets/"
local tmp_folder = "/tmp/"

-- Utility functions table
local util = {}

-- Timer data
local timerdata = {}
local timers = {}

-- External mode data
local ewidgets = {}

-- Some default values
local defaults = {}
defaults.update_time = 1
defaults.file_update_time = 2
defaults.format_string = "$1"
defaults.separator = " "
defaults.updater = "runner.sh"

-- State variable
local is_running = false

-- # Utility functions

--- Split string by separator into table
-- @param str String to split
-- @param sep Separator to use
function util.split(str, sep)
	if sep == nil then
		return {str}
	end

	local parts = {} --parts array
	local first = 1
	local ostart, oend = string.find(str, sep, first, true) --regexp disabled search

	while ostart do
		local part = string.sub(str, first, ostart - 1)
		table.insert(parts, part)
		first = oend + 1
		ostart, oend = string.find(str, sep, first, true)
	end

	local part = string.sub(str, first)
	table.insert(parts, part)

	return parts
end

function util.tmpkey(script)
	-- Replace all slashes with empty string so that /home/user1/script.sh 
	-- and /home/user2/script.sh will have different temporary files
	local tmpname = string.gsub(script, '/', '')

	-- Replace all spaces with dots so that "script.sh arg1"
	-- and "script.sh arg2" will have different temporary files
	tmpname = string.gsub(tmpname, '%s+', '.')

	return tmpname
end

function util.tmpname(script)
	-- Generated script-parameter unique temporary file path
	local file = tmp_folder .. util.tmpkey(script) .. '.bashets.out'

	return file
end

function util.fullpath(script)
	if string.find(script, '^/') == nil then
		script = script_path .. script
	end

	return script
end

--- Execute a command and write it's output to temporary file
-- @param script Script to execute
-- @param file File for script output
function util.execfile(script, file)
	-- Spawn command and redirect it's output to file
	awful.util.spawn_with_shell(script .. " > " .. file)
end


function util.readstring(str, sep)
	if sep == nil then
		return str
	else
		parts = util.split(str, sep);
		return parts
	end
end

--- Read temporary file to a table or string
-- @param file File to be read
-- @param israw If true, return raw string, not table
function util.readfile(file, sep)
	local fh = io.input(file)
	local str = fh:read("*all");
	io.close(fh)

	return util.readstring(str, sep)
end

--- Read script output to a table or string
-- @param script Script to execute
-- @param israw If true, return raw string, not table
function util.readshell(script, sep)
	local str = awful.util.pread(script)

	return util.readstring(str, sep)
end

--- Format script output with user defined format string
-- @param output sep-separated string of values
-- @param format Format string
-- @param sep Separator of values in string
function util.format(parts, format, sep)
	-- For each part with number "k" replace corresponding "$k" variable in format string
	for k,part in pairs(parts) do
		local part = string.gsub(part, "%%", "%1%1") --percent fix for next gsub (bug found in Wicked)
		part = awful.util.escape(part) --escape XML entities for correct Pango markup
		format = string.gsub(format, "$" .. k, part)
	end

	return format
end

--- Add function to corresponding timer object (Awesome >= 3.4 timer API)
-- @param updtime Update time for widget, also dispatch time for timer
-- @param func Function to dispatch
function util.add_to_timings(updtime, func, force_new)
	local found = false

	-- Search for an existing timer at the same period
	for k,tmr in pairs(timerdata) do
		if tmr[1] == updtime and (force_new == nil or force_new == false) then
			table.insert(timerdata[k][2], func)
			found = true
		end
	end

	-- Add a new timer for period if not found
	if not found then
		table.insert(timerdata, {updtime, {func}})
	end
end

--- Create timer table to define timers for multiple widget updates
function util.create_timers_table()
	-- Parse table with timer data
	for _,tmr in pairs(timerdata) do
		-- Create timer for the period
		local t
		if capi.timer ~= nil then
			t = capi.timer {timeout = tmr[1]}
		else
			t = timer {timeout = tmr[1]}
		end
		-- Function to call all dispatched functions
		local f = function()
			for _, func in pairs(tmr[2]) do
				func()
			end
		end
		
		if t.add_signal ~= nil then
			t:add_signal("timeout", f)
		else
			t:connect_signal("timeout", f)
		end
		table.insert(timers, t)
	end
end

function util.update_widget_field(widget, valuess)
--	print(widget.type)
	if widget.type == "imagebox" then				--imagebox (old API)
		widget["image"] = image(valuess)
	elseif widget.set_image ~= nil then				--imagebox (new API)
		--widget["image"] = capi.oocairo.image_surface_create_from_png(valuess)
		--widget:set_image(capi.oocairo.image_surface_create_from_png(valuess))
		widget:set_image(valuess)
	elseif widget.type == "textbox" then				--textbox (old API)
		widget["text"] = valuess
	elseif widget.set_markup ~= nil then				--textbox (new API)
		widget:set_markup(valuess)
	--elseif widget["widget"] ~= nil then
		elseif widget.set_value ~= nil then				--progressbar
			widget:set_value(tonumber(valuess))
		elseif widget.add_value ~= nil then			--graph
			widget:add_value(tonumber(valuess))
		end
	--end
end

--- Update widget from values
function util.update_widget(widget, values, format)
	if widget ~= nil then
		if type(values) == "table" then
			util.update_widget_field(widget, util.format(values, format))			
		else
			util.update_widget_field(widget, values)
		end
	end
end

-- # Setter functions

--- Set path for scripts
-- @param path Path to set
function bashets.set_script_path(path)
	script_path = path
end

--- Set path for temporary files
-- @param path Path to set
function bashets.set_temporary_path(path)
	tmp_folder = path
end

--- Set default values
-- @param defs Table with defaults
function bashets.set_defaults(defs)
	if type(defs) == "table" then
		if defs.update_time ~= nil then
			defaults.update_time = defs.update_time
		end 
		if defs.file_update_time ~= nil then
			defaults.file_update_time = defs.file_update_time
		end 
		if defs.format_string ~= nil then
			defaults.format_string = defs.format_string
		end
		if defs.updater ~= nil then
			defaults.updater = defs.updater
		end 

		defaults.separator = defs.separator --now could be nil
	end
end


-- # Acting functions

--- Start widget updates
function bashets.start()
	-- Create timers table if not initialized or empty
	if (not timers) or table.maxn(timers) == 0 then
		util.create_timers_table()
	end
	-- Start all timers
	for _, tmr in pairs(timers) do
		tmr:start()
	end

	-- Kill all externals (if some were here from previous launch)
	--awful.util.spawn_with_shell('killall ' .. defaults.updater)

	-- Run all externals
	for _, wgt in pairs(ewidgets) do
		awful.util.spawn_with_shell(wgt.cmd)
	end
	is_running = true
end

--- Stop widget updates
function bashets.stop()
	-- Stop all timers
	for _, tmr in pairs(timers) do
		tmr:stop()
	end

	-- Kill all externals
	awful.util.spawn_with_shell('killall ' .. defaults.updater)

	is_running = false
end

--- Check whether updates are running
function bashets.get_running()
	return is_running
end

--- Toggle updates
function bashets.toggle()
	if is_running then
		bashets.start()
	else
		bashets.stop()
	end
end

--- Shedule function for timed execution
-- @param func Function to run
-- @param updatime Update time (optional)
function bashets.schedule(func, updtime)
	updtime = updtime or defaults.update_time
	if func ~= nil then
		util.add_to_timings(updtime, func)
	end
end

-- # Widget registration functions

--- General widget-callback registration function. For internal use, but if you need it, feel free to call it :)
-- @param data_provider Function that returns table of values
-- @param widget Widget to update, if null, nothing is updated
-- @param callback Callback to call after the update of values, if null, nothing is called
-- @param format Format string for widget //N.B.: it is not checked for null
function bashets.schedule_w(data_provider, widget, callback, format, updtime)
	if callback ~= nil and type(callback) == "function" then
		if widget ~= nil then
			bashets.schedule(function()
				local data = data_provider()
				util.update_widget(widget, data, format)
				callback(data)
			end, updtime)
		else
			bashets.schedule(function()
				local data = data_provider()
				callback(data)
			end, updtime)
		end
	elseif widget ~= nil then
		bashets.schedule(function()
			local data = data_provider()
			util.update_widget(widget, data, format)
		end, updtime)
	end
end

--- External script registration. Script will pass data by calling external_w through dbus
function bashets.schedule_e(script, widget, callback, format, updtime, sep)
	local ascript = util.fullpath(script)
	local key = util.tmpkey(ascript)

	ewidgets[key] = {}
	ewidgets[key].widget = widget
	ewidgets[key].callback = callback
	ewidgets[key].format = format
	ewidgets[key].separator = sep
	ewidgets[key].cmd = util.fullpath(defaults.updater) .. " \"" .. ascript .. "\" " .. key .. " " ..updtime
	--print(ewidgets[key].cmd)
	
--	awful.util.spawn_with_shell()
end

function bashets.external_w(raw_data, key)

	local callback = ewidgets[key].callback or nil
	local widget = ewidgets[key].widget or nil
	local format = ewidgets[key].format or defaults.format_string
	local data = util.readstring(raw_data, ewidgets[key].separator)

	if callback ~= nil and type(callback) == "function" then
		if widget ~= nil then
			util.update_widget(widget, data, format)
			callback(data)
		else
			callback(data)
		end
	elseif widget ~= nil then
		util.update_widget(widget, data, format)
	end
end

function bashets.register_d(bus, iface, widget, callback, format)
	if capi.dbus then
		bus = bus or "session"
		capi.dbus.add_match(bus, "interface='" .. iface .. "'")
		
		capi.dbus.connect_signal(iface, function (...) 
			local argums = {...}
			local data = {}
			for _,v in pairs(argums) do
				if type(v) == "table" then
					for _,iv in pairs(v) do
						table.insert(data, iv)
					end
				else
					table.insert(data, v)
				end
			end

			if callback ~= nil and type(callback) == "function" then
				if widget ~= nil then
					util.update_widget(widget, data, format)
					callback(data)
				else
					callback(data)
				end
			elseif widget ~= nil then
				util.update_widget(widget, data, format)
			end
		end)
	else
		error("bashets: You are trying to employ dbus, but no dbus api detected in your build of awesome")
	end
end



--- Register script for text widget
-- @param object Object to be a data provider (function or string with a path to file/shellscript)
-- @param options Options table with following content (all fields are optional):
--
-- 	widget Widget to update
-- 	callback Function to execute after the update (should have a single parameter which represents table with data)
--  NOTE: you can use the widget without a callback, the callback without a widget, or both
--
-- 	update_time Widget update time (in seconds)
-- 	separator Output separator (string, could be null)
-- 	format User-defined format string (any valid Pango markup with variables)
--
-- 	async Perform script execution through a temporary file (true/false)
-- 	file_update_time Temporary file content update time (in seconds)
--
-- 	read_file Read file instead of executing it
function bashets.register(object, options)
	-- Set optional variables
	options = options or {}
	local updtime = options.update_time or defaults.update_time
	local fltime = options.file_update_time or defaults.file_update_time
	local format = options.format or defaults.format_string
	local sep = options.separator or defaults.separator
	local callback = options.callback
	local async = options.async or false
	local isdbus = options.dbus or false
	local busname = options.busname or "session"
	local readfile = options.read_file or false
	local widget = options.widget
	local external = options.external or false

	if type(object) == "function" then		--We have a function as a data provider
		-- Do it first time
		local data = func()
		util.update_widget(widget, data, format)
		
		-- Schedule it for timed execution
		bashets.schedule_w(func, widget, callback, format, updtime)

	elseif readfile	then				--We have a text file as a data provider
		-- Do it first time
		local data = util.readfile(object, sep)
		util.update_widget(widget, data, format)

		-- Schedule it for timed execution
		bashets.schedule_w(function() return util.readfile(object, sep) end, widget, callback, format, updtime)

	elseif async then				--Script could hang Awesome, we need to run it
		local script = util.fullpath(object)		--through a temporary file
		local tmpfile = util.tmpname(script)

		-- Create temporary file if not exists
		fl = io.open(tmpfile, "w")
		io.close(fl)

		-- Do it first time
		util.execfile(script, tmpfile)
		local data = util.readfile(tmpfile, sep)
		util.update_widget(widget, data, format)

		-- Schedule it for timed execution
		bashets.schedule(function() util.execfile(script, tmpfile) end, fltime)
		bashets.schedule_w(function() return util.readfile(tmpfile, sep) end, widget, callback, format, updtime)

	elseif external then		-- Script provides external data through dbus
		local script = util.fullpath(object)
		bashets.schedule_e(script, widget, callback, format, updtime, sep)
	elseif isdbus then			-- Data is fetched through a message bus
		bashets.register_d(busname, object, widget, callback, format)
		--print("registered with bus name \"" .. busname .. "\" and object \"" .. object .. "\"")
	else						-- Fast script that can be read through pread
		local script = util.fullpath(object)

		-- Do it first time
		local data = util.readshell(script, sep)
		util.update_widget(widget, data, format)

		-- Schedule it for timed execution
		bashets.schedule_w(function() return util.readshell(script, sep) end, widget, callback, format, updtime)
	end

end

return bashets
