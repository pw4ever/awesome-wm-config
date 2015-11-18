package.path = package.path .. ";./?/init.lua;"

local awful = require("awful")
local naughty = require("naughty")
local rudiment = require("../rudiment")
-- some miscellaneous functions
misc = {}

-- my own notification. Turn previous notification off if used again
misc.notify =  {}
misc.notify.togglelist = {}

misc.IO = {}
misc.Volume = {}
misc.Volume.step = "1%"
misc.Volume.control = "Master"

function misc.notify.volume (options)
    local vol = "<span face='monospace'>" .. awful.util.pread("myscripts/showvol.sh") .. "</span>"
    options = awful.util.table.join(options, {
        preset = naughty.config.presets.normal,
        title="Volume Info",
        text=vol,
        timeout = 0,
        screen = mouse.screen,
    })
    misc.notify.togglelist.volnotify = naughty.notify(options)
end

function misc.notify.togglevolume ()
    if misc.notify.togglelist.volnotify then
        naughty.destroy(misc.notify.togglelist.volnotify)
        misc.notify.togglelist.volnotify = nil
        return
    end
    misc.notify.volume()
end

function misc.notify.toggleAwesomeInfo()

    if misc.notify.togglelist.awesomeInfo then
        naughty.destroy(misc.notify.togglelist.awesomeInfo)
        misc.notify.togglelist.awesomeInfo = nil
        return
    end

    local info = "Version: " .. awesome.version 
    info = info ..  "\n" .. "Release: " .. awesome.release
    info = info ..  "\n" .. "Config: " .. awesome.conffile
    info = info ..  "\n" .. "Config Version: " .. rudiment.config.version 
    info = info ..  "\n" .. "Config Help: " .. rudiment.config.help_url
    if awesome.composite_manager_running then
        info = info .. "\n" .. "<span fgcolor='red'>a composite manager is running</span>"
    end
    local uname = awful.util.pread("uname -a")
    if string.gsub(uname, "%s", "") ~= "" then
        info = info .. "\n" .. "OS: " .. string.gsub(uname, "%s+$", "")
    end
    -- remove color code from screenfetch output
    local archey = awful.util.pread("screenfetch -N")
    if string.gsub(archey, "%s", "") ~= "" then
        info = info .. "\n\n<span face='monospace'>" .. archey .. "</span>"
    end
    info = string.gsub(info, "(%u[%a ]*:)%f[ ]", "<span color='red'>%1</span>")
    local tmp = awesome.composite_manager_running
    awesome.composite_manager_running = false
    misc.notify.togglelist.awesomeInfo = naughty.notify({
        preset = naughty.config.presets.normal,
        title="awesome info",
        text=info,
        timeout = 10,
        screen = mouse.screen,
    })
    awesome.composite_manager_running = tmp
end





function misc.Volume.Change (Master, step, dire)
    awful.util.spawn("amixer sset " .. Master .. " " .. step .. dire)
    if misc.notify.togglelist.volnotify then
        misc.notify.volume({replaces_id = misc.notify.togglelist.volnotify.id})
    end
end

function misc.Volume.Up ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "+")
end

function misc.Volume.Down ()
    misc.Volume.Change(misc.Volume.control,  misc.Volume.step, "-")
end


-- 

-- hack for lua eval
function misc.lua_completion (line, cur_pos, ncomp)
   -- Only complete at the end of the line, for now
   if cur_pos ~= #line + 1 then
      return line, cur_pos
   end

   -- We're really interested in the part following the last (, [, comma or space
   local lastsep = #line - (line:reverse():find('[[(, ]') or #line)
   local lastidentifier
   if lastsep ~= 0 then
      lastidentifier = line:sub(lastsep + 2)
   else
      lastidentifier = line
   end

   local environment = _G

   -- String up to last dot is our current environment
   local lastdot = #lastidentifier - (lastidentifier:reverse():find('.', 1, true) or #lastidentifier)
   if lastdot ~= 0 then
      -- We have an environment; for each component in it, descend into it
      for env in lastidentifier:sub(1, lastdot):gmatch('([^.]+)') do
         if not environment[env] then
            -- Oops, no such subenvironment, bail out
            return line, cur_pos
         end
         environment = environment[env]
      end
   end

   local tocomplete = lastidentifier:sub(lastdot + 1)
   if tocomplete:sub(1, 1) == '.' then
      tocomplete = tocomplete:sub(2)
   end
   local completions = {}
   for k, v in pairs(environment) do
      if type(k) == "string" and k:sub(1, #tocomplete) == tocomplete then
         table.insert(completions, k)
      end
   end

   if #completions == 0 then
      return line, cur_pos
   end
   while ncomp > #completions do
      ncomp = ncomp - #completions
   end

   local str = ""
   if lastdot + lastsep ~= 0 then
      str = line:sub(1, lastsep + lastdot + 1)
   end
   str = str .. completions[ncomp]
   cur_pos = #str + 1
   return str, cur_pos
end

function misc.usefuleval(s)
	local f, err = loadstring("return "..s);
	if not f then
		f, err = loadstring(s);
	end
	if f then
		setfenv(f, _G);
		local ret = { pcall(f) };
		if ret[1] then
			-- Ok
			table.remove(ret, 1)
			local highest_index = #ret;
			for k, v in pairs(ret) do
				if type(k) == "number" and k > highest_index then
					highest_index = k;
				end
				ret[k] = select(2, pcall(tostring, ret[k])) or "<no value>";
			end
			-- Fill in the gaps
			for i = 1, highest_index do
				if not ret[i] then
					ret[i] = "nil"
				end
			end
			if highest_index > 0 then
				naughty.notify({ awful.util.escape("Result"..(highest_index > 1 and "s" or "")..": "..tostring(table.concat(ret, ", "))), screen = mouse.screen});
			else
				naughty.notify({ "Result: Nothing", screen = mouse.screen})
			end
		else
			err = ret[2];
		end
	end
	if err then
		naughty.notify({ awful.util.escape("Error: "..tostring(err)), screen = mouse.screen})
	end
end
return misc
