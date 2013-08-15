BSD volume widget
=================

This widget uses mixer to get and set the current volume level and it also
exports functions you can use in keybindings to change the volume of your
soundcard.

To add this widget to your configuration, insert

    require("obvious.volume_freebsd")

into the top of your rc.lua and add `obvious.volume_freebsd()` to your wibox.

Optionally you can specify the channel to be controlled like this:

    obvious.volume_alsa(channel)

the default channel is "vol", you might need to set it to "pcm".

The following functions can be used to raise/lower the volume of a soundcard
and to mute it:

* `obvious.volume_freebsd.raise(channel, v)` where `v` is optional and the value to raise the volume by (1 is the default)
* `obvious.volume_freebsd.lower(channel, v)` where `v` is optional and the value to lower the volume by (1 is the default)

Scrolling up and down on a widget changes the volume by 1. If you hold the
`Control` key while scrolling, the volume is changed by 5 and if you hold
`Shift`, it is changed by 10.

If you want to use the data gathered by this widget, you can use the function

    obvous.volume_freebsd.get_data(channel)

It returns nil on failure, otherwise it returns a table with the following fields:

* `volume`: a number representing the current volume from 0 to 100
