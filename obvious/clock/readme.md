Clock Widget
============

This widget is a powerful clock. It has a normal view, a roll-over view, and
configurable, time-based alarms. When an alarm is shown, the clock will change
its colour to indicate that. If you then click on it, all alarms since the last
click are shown.

Settings Available:
-------------------
* `set_editor("xterm -e vim")`: Set which editor to use. There is no default,
  so this is needed.
* `set_shortformat("%a %b %d")`: Set the format of the short display. You may
  specify either a string which has a format that os.date() can understand
  (man date has the formats), or a function that returns the usable format.
* `set_longformat(function () return "%T %a %b %d %Y" end)`: Set the format of
  the long display. You may specify either a string which has a format that
  `os.date()` can understand (`man date` has the formats), or a function that
  returns the usable format.
* `set_shorttimer(n)`: Set the delay between updates to `n`
* `set_longtimer(n)`: Set the long delay between updates to `n`, this is used
  when obvious is suspended.

To set one of these settings, simply do something like:

    obvious.clock.set_editor("xterm -e vim")

Implementation:
---------------
To use it, include it into your rc.lua by inserting this line:

    require("obvious.clock")

Then configure at least the editor setting (see Settings Available).

To finish your rc.lua changes, add the clock widget to your wibox's
widget list by adding:

    obvious.clock()

Finally, you want to create the alarm file. The alarm file is contained
in `${XDG_CONFIG_DIR}/awesome/alarms`. In most cases this would be
`~/.config/awesome/alarms`. The alarm file has a format like:

    14:30
    get pizza from oven

These alarms (each consisting of two lines) are shown with naughty. The first
line of each entry is a Lua regular expression to match against the time in
strftime format `%a-%d-%m-%Y:%H:%M`, which looks like this:

    Tue-26-05-2009:22:01

The second line contains the message to show. You can use `\n` inside the message
body if you want a newline.
