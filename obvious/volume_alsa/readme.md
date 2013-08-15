ALSA volume widget
==================

This widget uses amixer to get and set the current volume level and it also
exports functions you can use in keybindings to change the volume and
mute/unmute your soundcard.

To add this widget to your configuration, insert

    require("obvious.volume_alsa")

into the top of your rc.lua and add `obvious.volume_alsa()` to your wibox.

Optionally you can specify the cardid and channel to be controlled like this:

    obvious.volume_alsa(cardid, channel)

the default channel is "Master", you might need to set it to "PCM".

The following functions can be used to raise/lower the volume of a soundcard
and to mute it:

* `obvious.volume_alsa.raise(cardid, channel, v)` where `v` is optional and
  the value to raise the volume by (1 is the default)
* `obvious.volume_alsa.lower(cardid, channel, v)` where `v` is optional and
  the value to lower the volume by (1 is the default)
* `obvious.volume_alsa.mute(cardid, channel)`

If you left-click on a volume widget, the card is muted/unmuted. Right-clicking
opens a terminal with `alsamixer` in it. The terminal can be set with
`:set_term(t)` appended to the widget in the wibox. Changing it to `xterm`
would look like this:

    w.widgets = {
        obvious.volume_alsa(0, "PCM"):set_term("xterm")
    }

Scrolling up and down on a widget changes the volume by 1. If you hold the
`Control` key while scrolling, the volume is changed by 5 and if you hold
`Shift`, it is changed by 10.

If you want to use the data gathered by this widget, you can use the function

    obvous.volume_alsa.get_data(cardid, channel).

It returns nil on failure, otherwise it returns a table with the following fields:

* `volume`: a number representing the current volume from 0 to 100
* `mute` : a boolean value describing whether the channel is muted or not
