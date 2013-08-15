-----------------------------------
-- Author: Uli Schlachter        --
-- Copyright 2009 Uli Schlachter --
-- Copyright 2009 Majic          --
-----------------------------------

local beautiful = require("beautiful")
local tostring = tostring

module('obvious.lib.markup')

fg = {}
bg = {}

--[[

-- Little map of how I
-- organized this for usage.

  +-- markup
  |
  |`-- bold()        Set bold.
  |`-- italic()      Set italicized text.
  |`-- strike()      Set strikethrough text.
  |`-- underline()   Set underlined text.
  |`-- big()         Set bigger text.
  |`-- small()       Set smaller text.
  |`-- font()        Set the font of the text.
  |
  |`--+ bg
  |   |
  |   |`-- color()   Set background color.
  |   |`-- focus()   Set focus  background color.
  |   |`-- normal()  Set normal background color.
  |    `-- urgent()  Set urgent background color.
  |
  |`--+ fg
  |   |
  |   |`-- color()   Set foreground color.
  |   |`-- focus()   Set focus  foreground color.
  |   |`-- normal()  Set normal foreground color.
  |    `-- urgent()  Set urgent foreground color.
  |
  |`-- focus()       Set both foreground and background focus  colors.
  |`-- normal()      Set both foreground and background normal colors.
   `-- urgent()      Set both foreground and background urgent colors.

]]

-- Basic stuff...
function bold(text)      return '<b>'     .. tostring(text) .. '</b>'     end
function italic(text)    return '<i>'     .. tostring(text) .. '</i>'     end
function strike(text)    return '<s>'     .. tostring(text) .. '</s>'     end
function underline(text) return '<u>'     .. tostring(text) .. '</u>'     end
function big(text)       return '<big>'   .. tostring(text) .. '</big>'   end
function small(text)     return '<small>' .. tostring(text) .. '</small>' end

function font(font, text)
  return '<span font_desc="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end

-- Set the foreground.
function fg.color(color, text)
  return '<span foreground="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end

-- Set the background.
function bg.color(color, text)
  return '<span background="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end

-- Context: focus
function fg.focus(text)  return fg.color(beautiful.fg_focus, text)  end
function bg.focus(text)  return bg.color(beautiful.bg_focus, text)  end
function    focus(text)  return bg.focus(fg.focus(text))     end

-- Context: normal
function fg.normal(text) return fg.color(beautiful.fg_normal, text) end
function bg.normal(text) return bg.color(beautiful.bg_normal, text) end
function    normal(text) return bg.normal(fg.normal(text))   end

-- Context: urgent
function fg.urgent(text) return fg.color(beautiful.fg_urgent, text) end
function bg.urgent(text) return bg.color(beautiful.bg_urgent, text) end
function    urgent(text) return bg.urgent(fg.urgent(text))   end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=4:softtabstop=4:encoding=utf-8:textwidth=80
