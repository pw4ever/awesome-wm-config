<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [[awesome Window Manager][awesome] configuration](#awesome-window-managerawesome-configuration)
	- [intro](#intro)
	- [setup](#setup)
		- [patching](#patching)
		- [install on Linux](#install-on-linux)
		- [dependencies](#dependencies)
		- [miscellaneous](#miscellaneous)
	- [usage](#usage)
		- [window management](#window-management)
			- [restart/quit](#restartquit)
			- [**layout**](#layout)
			- [multiple screens/multi-head/[RANDR](https://en.wikipedia.org/wiki/RandR)](#multiple-screensmulti-headrandrhttpsenwikipediaorgwikirandr)
			- [misc](#misc)
		- [**dynamic tagging**](#dynamic-tagging)
			- [**add/delete/rename**](#adddeleterename)
			- [view](#view)
			- [move](#move)
		- [client management](#client-management)
			- [operation](#operation)
			- [change focus](#change-focus)
			- [swap order/select master](#swap-orderselect-master)
			- [reorder client on current tag](#reorder-client-on-current-tag)
			- [move/copy to tag](#movecopy-to-tag)
			- [change space allocation in **tile** layout](#change-space-allocation-in-tile-layout)
		- [app bindings](#app-bindings)
			- [admin](#admin)
			- [everyday](#everyday)
			- [rest](#rest)
	- [todo](#todo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# [awesome Window Manager][awesome] configuration

<<<<<<< HEAD
## intro
=======
patch
-----

Known to work with *awesome v3.5.2 (The Fox).*

An [upstream bug report][] is filed to address dynamic tagging regression in v3.5.3 and v3.5.4.

patch against v3.5.4 (and Arch Linux PKGBUILD) can be found in this repo under 00patch/v3.5.4/
>>>>>>> cd53bd1cb9a129c86ccab408c71b400cdf06bc39

[awesome][awesome] is awesome. I use it on all [Arch Linux][archlinux] desktop/laptop machines that I have control over (admittedly, it is not designed for handheld smartphones/tablets).

[Search YouTube for "awesome wm"](https://www.youtube.com/results?search_query=awesome+wm) to see [awesome][awesome] in action.

Among my favorites features:
* keyboard driven workflow ([again, see this in action on YouTube](https://www.youtube.com/results?search_query=awesome+wm)).
* customizable through the [Lua programming language][lua].
* one-key-combo switching between [tiling](https://en.wikipedia.org/wiki/Tiling_window_manager) and [stacking](https://en.wikipedia.org/wiki/Stacking_window_manager) window management styles.
* *the ability* to do dynamic tagging (meaning it is **not** enabled by the default configuration---at least up to v3.5.4 (Brown Paper Bag) released on 2 April 2014).

This repo holds my *personal* take of [awesome][awesome]'s configuration. Hightlights:
* *persistent dynamic tagging* across (both regular and randr-induced) restarts.
  * dynamic tagging means tags can be created/moved/renamed/deleted on the fly without touching the configuration.
  * persistent means tags and the clients/programs associated with each tag is preserved across [awesome][awesome] restart.
    * [apparently, I am not the only one who desire this](https://awesome.naquadah.org/bugs/index.php?do=details&task_id=687)
  * this is **the** feature I have desired for that is lacking in current default configuration.
* confirmation before quit/restart to minimize data loss accidents.
  * you have to type "yes" (case insensitive) before quitting/restarting.
  * this minimizes the chance that you lose your work by accidents.
* keybindings to *my* preferred applications.
* only cycle through the most sensible (IMHO) layouts.
* keybinding optimized for [Arch Linux][archlinux] over Thinkpad W530 (my current workhorse).

## setup

### patching

This configuration is known to work with awesomeWM/awesome@v3.5.2

[awesome][awesome] releases from awesomeWM/awesome@v3.5.3 to (at least) awesomeWM/awesome@v3.5.4 has a commit (awesomeWM/awesome@9c69e8) that obliterates the order of dynamic tags. I have [filed an upstream bug report](https://awesome.naquadah.org/bugs/index.php?do=details&task_id=1249) and released a patch against it.

Options for patching:
* [the raw patch](https://raw.githubusercontent.com/pw4ever/awesome-wm-config/master/00patch/v3.5.4/awful-tag.patch).
* [Arch Linux PKGBUILD](https://raw.githubusercontent.com/pw4ever/awesome-wm-config/master/00patch/v3.5.4/PKGBUILD).
* [my patched awesome repo](https://github.com/pw4ever/awesome) forked from upstream.

### install on Linux

* install [awesome][awesome] with either:
  * your preferred package manager (`sudo pacman -S awesome --needed --noconfirm` on [Arch Linux][archlinux]) or
  * manually: [my awesome fork](https://github.com/pw4ever/awesome/tree/bugfix) has an [installation shell script](https://raw.githubusercontent.com/pw4ever/awesome/bugfix/00make-in-archlinux.sh).
* Clone to `$HOME/.config/awesome`.
```bash
cd $HOME/.config && git clone https://github.com/pw4ever/awesome-wm-config.git awesome
```
* setup .xinitrc or Display Manager accordingly

### dependencies

These dependencies are mostly derived from the application keybindings. Some are needed to enable basic features like theming (`feh`), [Desktop Entry Specification](http://standards.freedesktop.org/desktop-entry-spec/latest/)-style autostart (`dex`), audio setup (`alsa-utils`), backlight (`xorg-xbacklight`), Webcam (`cheese`), music player (`mpd` and `mpc`), screen lock (`xscreensaver`), network management (`network-manager-applet`), terminal (`sakura`), and screen setup (`arandr`), etc..

On [Arch Linux][archlinux]:

```bash
sudo pacman -S --needed --noconfirm \
         feh dex \
         alsa-utils xorg-xbacklight cheese mpd mpc \
         xscreensaver networkmanager network-manager-applet sakura arandr \
         xfce4-goodies gksu \
         gvim emacs firefox chromium
```

### miscellaneous

* make sure that you can write to `/tmp` (for dynamic tagging), e.g., through `tmpfs`
* populate your `$HOME/.config/autostart` with [Desktop Entry Specification](http://standards.freedesktop.org/desktop-entry-spec/latest/)-style autostart files (optionally with `OnlyShowIn=awesome` if you only want them to auto-start in [awesome][awesome]).
* [my autostart setup can be found here](https://github.com/pw4ever/dev-env/tree/master/.config/autostart/awesome).

## usage

Take a look at the "rc.lua" configuration file (`$HOME/.config/awesome/rc.lua`; perhaps by pressing the keybinding `[modkey]+c` which will open `rc.lua` with the primary editor---for me, Vim).

Most keybindings are prefixed with the "Modkey." This config associates "Modkey" to X Window's "mod4" . On many machines, this associates the "Super_L" (tip: use `xmodmap` in terminal emulator to verify/change this), which usually translate to the (intuitively) "Windows" key.

Some keybinding requires further input (e.g., rename a tag), which will "grab" the key focus from your application. The `[esc]` key is used to cancel partial input.

### window management

#### restart/quit

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+r|restart|"r" for restart; used for apply updated "rc.lua" config file|
|[modkey]+[shift]+q|quit|"q" for quit; used for apply updated "rc.lua" config file|

#### **layout**

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[space]|change to next layout||
|[modkey]+[shift]+[space]|change to prev layout||


only the following layouts are enabled

| layout | comment |
| --- | --- |
| floating | allow window stacking; the default |
| tile | tiling with master on the left |
| fair | fair allocation of screen space |
| fullscreen | the focused client fullscreened |
| magnifier | the focused client centered but not fullscreened |

in the floating mode, the following mouse actions are enabled

| mouse action | comment |
| --- | --- |
|[modkey]+[left mouse button/button 1]| move client |
|[modkey]+[right mouse button/button 3]| resize client |

#### multiple screens/multi-head/[RANDR](https://en.wikipedia.org/wiki/RandR)

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+j|focus on the next screen|"j" is easy to reach|
|[modkey]+[ctrl]+j|focus on the prev screen|"k" is easy to reach|
|[modkey]+o|send client to the other screen||

#### misc

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[f1]|prompt a program to launch|inherited from awesome defaults|
|[modkey]+[f4]|prompt Lua code to be eval-ed in awesome|inherited from awesome defaults|
|[modkey]+c|edit "rc.lua" with the primary editor|"c" for configuration file|
|[modkey]+/|show main menu||
|[modkey]+[shift]+/|show main menu||
|[modkey]+\|launch screen saver/locker||
|[modkey]+[enter]|launch user terminal||
|[modkey]+[alt]+[enter]|launch root terminal||

### **dynamic tagging**

#### **add/delete/rename**

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+a|create a new tag after the current one and view it|"a" for add|
|[modkey]+[shift]+a|create a new tag before the current one and view it|"a" for add|
|[modkey]+[shift]+d|delte the current tag *if there is no client on it*|"d" for delete|
|[modkey]+[shift]+r|rename the current tag|"r" for rename|

#### view

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[left]|view previous tag||
|[modkey]+[right]|view next tag||
|[modkey]+p|view previous tag|"p" for previous|
|[modkey]+n|view next tag|"n" for next|
|[modkey]+[esc]|view last tag||
|[modkey]+z|view last tag||
|[modkey]+g|**prompted for a tag to view**|with tag name completion with [tab]|
|[modkey]+[1-9,0]|**view the first-ninth, tenth tag**|prompt for "add a new tag" if not already existed|
|[modkey]+[ctrl]+[1-9,0]|**view also the first-ninth, tenth tag**|prompt for "add a new tag" if not already existed|

#### move

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+p|move the current tag backward by 1 position||
|[modkey]+[ctrl]+n|move the current tag forward by 1 position||

### client management

#### operation

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[shift]+c|kill focused client||
|[modkey]+f|toggle fullscreen status|"fullscreen" hides statusbar|
|[modkey]+m|toggle maximized status|"maximized" leaves statusbar visible|
|[modkey]+[shift]+m|minimize|minimized client need mouse click on tasklist to restore|
|[modkey]+[ctrl]+[space]|toggle floating status||
|[modkey]+t|toggle ontop status||

#### change focus

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+j|focus on the next client in current tag|"j" is easy to reach|
|[modkey]+k|focus on the prev client in current tag|"k" is easy to reach|
|[modkey]+[tab]|focus on the last-focus client in current tag||
|[modkey]+[tab]|focus on the last-focus client in current tag||

#### swap order/select master

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+[enter]|select current client as the master|master is featured on the screen|
|[modkey]+[shift]+j|swap current client with the next one|"j" is easy to reach|
|[modkey]+[shift]+k|swap current client with the prev one|"k" is easy to reach|

#### reorder client on current tag

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[shift]+j|focus on the next client in current tag|"j" is easy to reach|
|[modkey]+k|focus on the prev client in current tag|"k" is easy to reach|

#### move/copy to tag

all these keys work on the single **currently focused client**

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[shift]+p|send client to previous tag|"p" for previous|
|[modkey]+[shift]+n|send client to next tag and|"n" for next|
|[modkey]+[shift]+g|**prompted for a tag to move client to**|with tag name completion with [tab]|
|[modkey]+[shift]+[1-9,0]|**move client to {first-ninth, tenth} tag**|prompt for "add a new tag" if not already existed|
|[modkey]+[shift]+[ctrl]+[1-9,0]|**copy client also the {first-ninth, tenth} tag**|prompt for "add a new tag" if not already existed|

#### change space allocation in **tile** layout

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+=|reset master width to 50%|"=" for equal partition of screen|
|[modkey]+l|increase master width by 5%|"l" towards right on keyboard|
|[modkey]+h|decrease master width by 5%|"h" towards left on keyboard|
|[modkey]+[shift]+l|increase number of masters by 1|"l" towards right on keyboard|
|[modkey]+[shift]+h|decrease number of masters by 1|"h" towards left on keyboard|
|[modkey]+[ctrl]+l|increase number of columns by 1|"l" towards right on keyboard|
|[modkey]+[ctrl]+h|decrease number of columns by 1|"h" towards left on keyboard|

### app bindings

shortcut keys are bound for most common apps; the keybinding is designed to be balanced between the left (pressing the [modkey]) and the right hand (an additional easy to reach key).

#### admin

| key combo | app | my choice |
| --- | --- | --- |
|[modkey]+[alt]+[enter] | root terminal | gksudo sakura |
|[modkey]+\ | screen saver/locker | xscreensaver |
|[modkey]+' | GUI appfinder | xfce4-appfinder |

#### everyday

| key combo | app | my choice |
| --- | --- | --- |
|[modkey]+l | file manager | thunar |
|[modkey]+[enter] | user terminal | sakura |
|[modkey]+p | remote terminal | putty |
|[modkey]+i | primary editor | gvim |
|[modkey]+[shift]+i | secondary editor | emacs |
|[modkey]+c | primary browser | chromium |
|[modkey]+[shift]+c | secondary browser | firefox |
|[modkey]+[alt]+v | secondary browser | virtualbox |

#### rest

* currently optimized for [Thinkpad W530 keyboard layout](http://shop.lenovo.com/us/en/laptops/thinkpad/w-series/w530/) ![](http://www.lenovo.com/images/OneWebImages/SubSeries/gallery/laptops/ThinkPad-W530-Laptop-PC-Overhead-Keyboard-View-gallery-940x529.jpg)
* take a look at [the config](https://github.com/pw4ever/awesome-wm-config/blob/master/rc.lua#L693) for details.

## todo

- [ ] improve persistent dynamic tagging: preserve tag configuration (e.g., layout style and client positions)

<<<<<<< HEAD
[awesome]: http://awesome.naquadah.org/
[archlinux]: https://www.archlinux.org/
[lua]: http://www.lua.org/
=======
[awesome]: http://awesome.naquadah.org/wiki/Main_Page "awesome wm wiki"
[upstream bug report]: https://awesome.naquadah.org/bugs/index.php?do=details&task_id=1249&project=1&order=dateopened&sort=desc
>>>>>>> cd53bd1cb9a129c86ccab408c71b400cdf06bc39
