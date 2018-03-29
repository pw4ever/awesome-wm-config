# foggy

[![Build Status](https://travis-ci.org/k3rni/foggy.svg?branch=master)](https://travis-ci.org/k3rni/foggy)

Foggy manages your multiple screens. It's an extension script for [Awesome](http://awesome.naquadah.org/), a tiling window manager. 

When foggy is invoked, it displays a popup menu that allows you to manipulate display outputs via XRandR. Most XRandR features are supported:

* relative screen positioning, as in "output X is right of output Y"
* cloning output
* rotations and reflections
* modesetting, restricted to XRandR-provided modes
* turning a display on and off
* backlight, if supported by that particular screen and XRandR
* additional display properties besides backlight: typically scaling mode, aspect ratio and audio output toggling

[Screenshots on imgur](http://imgur.com/a/EK1Hu).

# Installation

## Standalone

```shell
  cd ~/.config/awesome
  git clone https://gitlab.com/k3rni/foggy
```

## With [awesome-copycats](http://github.com/copycat-killer/awesome-copycats)

The instructions assume you went with the git-clone route. Go to .config/awesome as above, but add foggy as a submodule:

```shell
  git submodule add https://gitlab.com/k3rni/foggy
```

## Required software

Foggy should run with stock Xorg as installed on modern Linux systems. It uses some standard tools to read XRandR and Xinerama info. Check that `xdpyinfo`, `xrandr` are installed and on $PATH.

# Which version of Awesome are you using?

Foggy now supports Awesome 4.0 and higher by default. If you need it to work on Awesome 3.4 or 3.5, please use the `awesome-3.5` branch. 
Just append `-b awesome-3.5` to whichever of the commands above you're using.

# Usage

Edit your rc.lua, and add the following somewhere with the other require lines:

```lua
local foggy = require('foggy')
```

## Keys 

Restart your DE, or call awesome's Lua prompt (default: <kbd>Win + X</kbd>) and type <code>awesome.restart()</code>.
Now you can invoke Foggy by calling the Lua prompt and typing <code>foggy.menu()</code>.

To add a keybinding, edit rc.lua and add something like the following to the global key bindings: (don't forget to add a comma if necessary). The following binding mirrors Windows' default screen-switching keybinding, which some laptops' output-switch key might emit.

```lua
    awful.key({ modkey }, "p",      foggy.menu)
```

## Brightness control

```lua
   awful.key({ }, "XF86MonBrightnessUp", function() foggy.shortcuts.inc_backlight(10) end)
   awful.key({ }, "XF86MonBrightnessDown", function() foggy.shortuts.inc_backlight(-10) end)
```

If the brightness keys don't work, it might be an ACPI issue, not awesome's. In that case rebind to a convenient combination, such as modkey + the function keys that show brightness symbols.

Note: This'll only adjust backlight for whatever screen the cursor is currently in. If you need to adjust it across all screens, either call `inc_backlight` more than once, passing a screen number in the second parameter; or use the standalone `xbacklight` command instead.

See [Backlight on wiki](https://gitlab.com/k3rni/foggy/wikis/Backlight) for more info.

## Widgets (do-it-yourself style)

To add a widget, add something similar to where the widget box is built. Replace the icon path, and background color if necessary (or just add the imagebox
directly, without the background).

```lua
    scrnicon = wibox.widget.background(wibox.widget.imagebox('path-to-image.png'), '#313131')
    scrnicon:buttons(awful.util.table.join(
                         awful.button({ }, 1, function (c)
                           foggy.menu(s)
                         end)
                     ))
    layout:add(scrnicon)
```

Restart awesome as above. Now, clicking that icon in the bar should bring up foggy.

# Problems?

[File an issue](https://gitlab.com/k3rni/foggy/issues/new) on GitLab. Be sure to include as much diagnostic information as possible. Check [Reporting errors](https://gitlab.com/k3rni/foggy/wikis/Reporting%20errors) on where to find it.

# Contributing

* fork the repository
* hack on code
* write specs for it! run them using [busted](http://olivinelabs.com/busted/), e.g `busted --helper spec/helper.lua spec/YOUR_SPEC.lua`
* create a pull request
