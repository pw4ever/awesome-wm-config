Battery widget
==============

This widget is a battery monitor. It gets its information from `acpi`, `acpitool`
or from `apm`, to be as uniquely usable as possible. With `apm` as the backend,
some information might not be available, such as whether the battery is currently
charged or whether it is discharging. Charge is displayed with either backends.
If you click on the widget, additional information is displayed. Currently,
only the first battery is monitored on the widget box, but information about
all other attached batteries is still visible if you click the widget.

To use it, include it into your rc.lua by inserting this line:

    require("obvious.battery")

into the top of your rc.lua. Then add the widget to your wibox. It's called

    obvious.battery()

If you want to use the data gathered by this widget to create your own, use the
function `obvious.battery.get_data()`. It returns nil on failure and it returns
a table on success. The table has the following fields:

* `state`: a string which describes the batteries' state as one element of the
  set `["charged", "full", "discharging", "charging"]` (most likely, some
  acpi implementations might output different values)
* `charge`: a number representing the current battery charge as a number between
  0 and 100
* `time`: a string describing the time left to full charge or complete discharge
  (the format and whether this field is filled at all depends on the acpi implementation)
