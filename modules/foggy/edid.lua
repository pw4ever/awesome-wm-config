local edid = {
}

function a2b(str)
  return string.gsub(str, "([a-f0-9][a-f0-9])", function(m)
    return string.char(tonumber(m, 16))
  end)
end

function edid.monitor_name(edid_str)
  return edid.parse_edid(edid_str).monitor_name
end

function edid.parse_edid(edid_str)
  local bytes = a2b(edid_str)
  local ord = string.byte
  local data = { }
  
  -- Source: https://en.wikipedia.org/wiki/Extended_Display_Identification_Data
  -- NOTE: all offsets in the spec are zero-based, while Lua's are one-based.

  data.monitor_name = nil
  local mfr0, mfr1 = ord(bytes, 11, 12)
  data.manufacturer_code = mfr0 + mfr1 * 2^8

  local sn0, sn1, sn2, sn3 = ord(bytes, 13, 16)
  data.serial_number = (sn0 + sn1 * 2^8 + sn2 * 2^16 + sn3 * 2^24)

  data.week_of_manufacture = ord(bytes, 17)
  data.year_of_manufacture = ord(bytes, 18) + 1990

  data.width_mm = ord(bytes, 22) * 10
  data.height_mm = ord(bytes, 23) * 10

  -- Descriptor blocks store things such as monitor name. Zero-based, corrected later.
  local descriptor_block_offsets = { { 54, 71 }, { 72, 89 }, { 90, 107 }, { 108, 125 } }

  for _, offset in ipairs(descriptor_block_offsets) do
    local low = offset[1] + 1
    local high = offset[2] + 1
    local desc_type = string.byte(bytes:sub(low + 3))
    if desc_type == 0xFC then -- monitor name, space-padded with a LF
      local monitor_name = bytes:sub(low + 5, high):gsub("[\r\n ]+$", "")
      data.monitor_name = monitor_name
    end
  end

  return data
end

return edid
