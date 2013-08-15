-----------------------------------------------
-- GPS widget for the awesome window manager --
-----------------------------------------------
-- Author: Christian Kuka chritian@kuka.cc   --
-- Copyright 2010 Christian Kuka             --
-- Licensed under GPLv2                      --
-----------------------------------------------

local assert = assert
local string = string
local tonumber = tonumber
local math = math
local setmetatable = setmetatable
local table = table
local io = {
    open = io.open
}
local capi = {
        widget = widget,
        mouse = mouse
}

local naughty = require("naughty")
local awful = require("awful")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

local lib = {
    hooks = require("obvious.lib.hooks"),
    markup = require("obvious.lib.markup")
}

module("obvious.gps")

widget = capi.widget({
    type = "textbox",
    name = "tb_gps",
    align = "right"
})

position = {
   date = 0,
   time = 0,
   latitude = 0.0,
   longitude = 0.0,
   quality = 0,
   altitude = 0.0,
   satellites = 0,
   satellitesData = {},
   dilution = 0.0,
   height = 0.0,
   status = "V",
   speed = 0.0,
   course = 0.0,
   variation = 0.0,
   node = ""
}


-- Set the local device for NMEA data
local device = "/dev/rfcomm0"
function set_device(dev)
   device = dev
end

-- Set the browser for opening openstreetmap
local browser = "/usr/bin/uzbl"
function set_browser(path)
   browser = path
end

-- Returns the position struct
function get_data()
   return position
end

-- Parse the NMEA messages (GGA, RMC, GSV)
local fh = nil
function parse_nmea(line)
    local msg = string.sub(line,0,6)
    if (msg == "$GPGGA") then
       -- Match GGA message
       local time, latitude, longitude, quality, satellites, dilution, altitude, height, checksum = line:match("^\$GPGGA,([0-9.]+),([0-9.]+),[NS],([0-9.]+),[EW],([0-8]?),([0-9]+),([0-9.]*),([0-9.-]+),M,([0-9.]+),M,,\*(.*)")
       latitude = tonumber(latitude)
       longitude = tonumber(longitude)
       local dd
       dd,_ = math.modf(latitude / 100)
       position.latitude = dd + (latitude - dd * 100) / 60
       dd,_ = math.modf(longitude / 100)
       position.longitude = dd + (longitude - dd * 100) / 60
       position.time = time
       position.quality = tonumber(quality)
       position.satellites = tonumber(satellites)
       position.dilution = tonumber(dilution)
       position.altitude = tonumber(altitude)
       position.height = tonumber(height)
    elseif (msg == "$GPRMC") then
       -- Match RMC message
       local time, status, latitude, longitude, speed, course, date, variation, node, checksum = line:match("^\$GPRMC,([0-9.]+),[AV],([0-9.]+),[NS],([0-9.]+),[EW],([0-9.]+),([0-9.]+),([0-9]+),([0-9.]*),[EW]?,([NADE])\*(.*)")
       latitude = tonumber(latitude)
       longitude = tonumber(longitude)
       local dd
       dd,_ = math.modf(latitude / 100)
       position.latitude = dd + (latitude - dd * 100) / 60
       dd,_ = math.modf(longitude / 100)
       position.longitude = dd + (longitude - dd * 100) / 60
       position.time = time
       position.date = date
       position.status = status
       position.speed = tonumber(speed)
       position.course = tonumber(course)
       position.variation = tonumber(variation)
       position.node = node

    elseif (msg == "$GPGSV") then
       -- TODO is satellite data needed?
       -- Match GSV message
       --local total, count, satellites, satellites, checksum = line:match("^\$GPGSV,([1-3]+),([1-3]+),([0-9]+),([0-9,]*)\*(.*)")

       -- Match satellites data
       -- local id, elevation, azimuth, snr = satellites:match("([0-9]{1,2}),([0-9]+),([0-9]+),([0-9]*)")
    end
end

-- Reverse geocode a position using geonames.org
function reverse_geocode()
   local c, err, h = http.request("http://ws.geonames.org/findNearbyPlaceNameJSON?lat="..position.latitude.."&lng="..position.longitude)
   if c then
      c = json.decode(c)
      return c.geonames[1]
    end
    return nil
end

-- Update position data
local function update()
   fh = io.open(device)
   if fh then
   local line = fh:read("*l")
   local maxlines = 3
   local l = 0
   while line and l < maxlines do
      parse_nmea(line)
      l = l + 1
   end
   fh:close()
end
   widget.text = string.format("%f,%f", position.latitude, position.longitude)
end

-- Show detail information about current position
local function detail()
   local d = string.format("Latitude:\t%f\nLongitude:\t%f\nAltitude:\t%f\nDilution:\t%f", position.latitude, position.longitude, position.altitude, position.dilution)
   naughty.notify({
                     text = d,
                     screen = capi.mouse.screen
                  })
end

-- Show reverse geocode position information
local function lookup()
   local geodata = reverse_geocode()
   if geodata then
      local d = string.format("Country:\t%s\nName:\t%s", geodata.countryName, geodata.name)
      naughty.notify({
                        text = d,
                        screen = capi.mouse.screen
                     })
   end
end

-- Open openstreetmap with current position
local function openmap()
   local link = "http://www.openstreetmap.org/?lat="..position.latitude.."&lon="..position.longitude.."&zoom=14&layers=B00FTF"
   awful.util.spawn(browser .. " " .. link)
end

widget:buttons(awful.util.table.join(
    awful.button({ }, 1, detail),
    awful.button({ }, 2, openmap),
    awful.button({ }, 3, lookup)
))

update()
lib.hooks.timer.register(60, 300, update)
lib.hooks.timer.start(update)

setmetatable(_M, { __call = function () return widget end })
