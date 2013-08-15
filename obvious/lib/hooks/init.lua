------------------------------------------
-- Author: Andrei "Garoth" Thorp        --
-- Copyright 2009 Andrei "Garoth" Thorp --
------------------------------------------
-- Awful Timer Wrapper With Speed Controls

local pairs = pairs
local capi = { timer = timer }

module("obvious.lib.hooks")

local registry = {}
timer = {}

-- Register a timer just as you would with awful.hooks.timer.register, but
-- with one slight twist: you set your regular speed, your slow
-- speed, and then your function.
-- @param reg_time Regular speed for the widget
-- @param slow_time (Optional) Slow time for the widget
-- @param fn The function that the timer should call
-- @param descr (Optional) The description of this function
function timer.register(reg_time, slow_time, fn, descr)
    if not slow_time then slow_time = reg_time * 4 end
    registry[fn] = {
        regular=reg_time,
        slow=slow_time,
        speed="regular",
        description=descr or "Undescribed timer",
        timer=capi.timer({ timeout = 600 })
    }
    registry[fn].timer:connect_signal("timeout", fn)
    -- set_speed() will :stop() again and start with the real timeout
    registry[fn].timer:start()
    timer.set_speed(registry[fn].speed, fn)
end

-- Unregister the timer altogether
-- Note: It's possible to pause the timer with timer.stop() instead.
-- @param fn The function you want to unregister.
function timer.unregister(fn)
    if registry[fn].timer.started then
        registry[fn].timer:stop()
    end
    registry[fn] = nil
end

-- Switch timers between "slow" and "regular" speeds.
-- @param speed The speed at which you want the function(s) to run: one of
-- "regular" or "slow"
-- @param fn (Optional) Function that you want to set to some speed. If not
-- not specified, set all timers to the given speed.
function timer.set_speed(speed, fn)
    if fn then
        local obj = registry[fn]
        obj.speed = speed
        if not registry[fn].timer.started then
            return
        end
        obj.timer:stop()
        local timeout = nil
        if speed == "regular" then
            timeout = obj.regular
        elseif speed == "slow" then
            timeout = obj.slow
        end
        if timeout then
            obj.timer.timeout = timeout
            obj.timer:start()
        end
    else
        for key, value in pairs(registry) do
            timer.set_speed(speed, key)
        end
    end
end

-- Edit a function's speeds.
-- @param reg_time Regular speed for the function
-- @param slow_time Slow speed for the function
-- @param fn Function that you want to alter the speed of
function timer.set_speeds(reg_time, slow_time, fn)
    registry[fn] = {
        regular=reg_time,
        slow=slow_time,
        speed=registry[fn].speed,
        timer=registry[fn].timer,
    }
    timer.set_speed(registry[fn].speed, fn)
end

-- Returns the speeds for the timer(s).
-- @param fn (Optional) Function that you want to know the data for. If not
-- specified, this returns a table of all registered timers with their data.
-- @return A table with the regular speed, the slow speed, the currently used
-- speed, whether the timer is running or not, and the description.
-- Note: This function returns a copy of the internal registry, so assigning to
-- it doesn't work.
function timer.get_speeds(fn)
    copy = {}
    if fn then
        for key, value in pairs(registry[fn]) do
            copy[key] = value
        end
    else
        for key, value in pairs(registry) do
            subcopy = {}
            for subkey, subvalue in pairs(registry[key]) do
                subcopy[subkey] = subvalue
            end
            copy[key] = subcopy
        end
    end
    return copy
end

-- Pause timer(s)
-- @param fn (Optional) Function to pause the timer for. If none is specified,
-- this pauses all registered timers.
function timer.stop(fn)
    if fn then
        registry[fn].timer:stop()
    else
        for key, value in pairs(registry) do
            registry[fn].timer:stop()
        end
    end
end

-- Start timer(s)
-- @param fn (Optional) Function to start the timer for. If none is specified,
-- this starts all registered timers.
function timer.start(fn)
    if fn then
        if not registry[fn].timer.started then
            registry[fn].timer:start()
        end
        timer.set_speed(registry[fn].speed, fn)
    else
        for key, value in pairs(registry) do
            if not registry[fn].timer.started then
                registry[fn].timer:start()
            end
            timer.set_speed(registry[key].speed, fn)
        end
    end
end

-- Checks whether the given function is registered
-- @return boolean true/false of whether the function is registered
function timer.has(fn)
    if registry[fn] then
        return true
    else
        return false
    end
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
