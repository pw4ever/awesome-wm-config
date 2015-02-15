<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [[awesome Window Manager][awesome] configuration](#awesome-window-managerawesome-configuration)
  - [intro](#intro)
  - [setup](#setup)
    - [install on Linux](#install-on-linux)
    - [dependencies](#dependencies)
    - [miscellaneous](#miscellaneous)
    - [patching](#patching)
      - [old note](#old-note)
  - [usage](#usage)
    - [window management](#window-management)
      - [restart/quit/info](#restartquitinfo)
      - [**layout**](#layout)
      - [multiple screens/multi-head/RANDR](#multiple-screensmulti-headrandr)
      - [misc](#misc)
    - [**dynamic tagging**](#dynamic-tagging)
      - [**add/delete/rename**](#adddeleterename)
      - [view](#view)
      - [move](#move)
    - [client management](#client-management)
      - [operation](#operation)
      - [change focus](#change-focus)
      - [swap order/select master](#swap-orderselect-master)
      - [move/copy to tag](#movecopy-to-tag)
      - [change space allocation in **tile** layout](#change-space-allocation-in-tile-layout)
      - [misc](#misc-1)
    - [app bindings](#app-bindings)
      - [admin](#admin)
      - [everyday](#everyday)
      - [the rest](#the-rest)
    - [tag list](#tag-list)
    - [task list](#task-list)
    - [root window/"the desktop"](#root-windowthe-desktop)
    - [window/task/client title bar](#windowtaskclient-title-bar)
  - [customization](#customization)
  - [todo](#todo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# [awesome Window Manager][awesome] configuration

<img alt="a screenshot of it in action" src="https://raw.githubusercontent.com/pw4ever/awesome-wm-config/master/screenshot/pengw-awesome-screenshot-20150215.png" width="960px" />

## intro

[awesome][awesome] is awesome. I use it on all [Arch Linux][archlinux] desktop/laptop machines that I have control over (admittedly, it is not designed for handheld smartphones/tablets).

[Me using it](https://www.youtube.com/watch?v=tu8nyU_vWh0) to demo [Figurehead](https://github.com/pw4ever/tbnl).

[Search YouTube for "awesome wm"](https://www.youtube.com/results?search_query=awesome+wm) to see [awesome][awesome] in action.

Among my favorites features:
* keyboard driven workflow ([again, see this in action on YouTube](https://www.youtube.com/results?search_query=awesome+wm)).
* customizable through the [Lua programming language][lua].
* one-key-combo switching between [tiling](https://en.wikipedia.org/wiki/Tiling_window_manager) and [stacking](https://en.wikipedia.org/wiki/Stacking_window_manager) window management styles.
* *the ability* to do dynamic tagging (meaning it is **not** enabled by the default configuration---at least up to v3.5.4 (Brown Paper Bag) released on 2 April 2014).

This repo holds my *personal* take of [awesome][awesome]'s configuration. Hightlights:
* **persistent dynamic tagging across (both regular and randr-induced) restarts**.
  * dynamic tagging means tags can be created/moved/renamed/deleted on the fly without touching the configuration.
  * persistent means tags and the clients/programs associated with each tag is preserved across [awesome][awesome] restart.
    * [apparently, I am not the only one who desire this](https://awesome.naquadah.org/bugs/index.php?do=details&task_id=687)
  * this is **the** feature I have desired for that is lacking in current default configuration.
* confirmation before quit/restart to minimize data loss accidents.
  * you have to type "yes" (case insensitive) before quitting/restarting.
  * this minimizes the chance that you lose your work by accidents.
* keybindings for tuning transparency (using `xcompmgr`), stay-on-top, sticky.
  * these features combined, along with tiling and floating layouts, allow you to type in one window while seeing the content of others.
* keybindings to *my* preferred applications.
* only cycle through the most sensible (IMHO) layouts.
* keybinding optimized for [Arch Linux][archlinux] over Thinkpad W530 (my current workhorse).

## setup

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
sudo pacman -S --needed --noconfirm feh dex xdg-utils screenfetch scrot xcompmgr kdeaccessibility wmname
sudo pacman -S --needed --noconfirm alsa-utils xorg-xbacklight cheese mpd mpc 
sudo pacman -S --needed --noconfirm xscreensaver networkmanager network-manager-applet mate-power-manager arandr xfce4-appfinder xfce4-screenshooter
sudo pacman -S --needed --noconfirm pcmanfm gvfs udisks udiskie lxsession lxappearance xarchiver 
sudo pacman -S --needed --noconfirm sakura conky gksu
sudo pacman -S --needed --noconfirm gvim emacs firefox chromium putty remmina qsynergy
sudo pacman -S --needed --noconfirm fcitx-im fcitx-googlepinyin fcitx-configtool
```

### miscellaneous

* make sure that you can write to `/tmp` (for dynamic tagging), e.g., through `tmpfs`
* populate your `$HOME/.config/autostart` with [Desktop Entry Specification](http://standards.freedesktop.org/desktop-entry-spec/latest/)-style autostart files (optionally with `OnlyShowIn=awesome` if you only want them to auto-start in [awesome][awesome]).
* [my autostart setup can be found here](https://github.com/pw4ever/awesome-wm-config/tree/master/autostart).

### patching

#### old note

The discussions on [the bug report](https://awesome.naquadah.org/bugs/index.php?do=details&task_id=1249)) result in upstream commits [27f483a](https://github.com/awesomeWM/awesome/commit/27f483a601b00366b6e87f929fd942b148e1812a) and [ec8db18](https://github.com/awesomeWM/awesome/commit/ec8db18289073be8e327262b4615f379cf2b3221). The patches fix this problem.

Therefore, this problem will be fixed in v3.5.5.

This configuration is known to work with [awesome v3.5.2][]

[awesome][awesome] releases from [awesome v3.5.3][] to (at least) [awesome v3.5.4][] has [a commit that obliterates the order of dynamic tags][awesome dynamic tag regression]. I have [filed an upstream bug report](https://awesome.naquadah.org/bugs/index.php?do=details&task_id=1249) and released a patch against it.

Options for patching:
* [the raw patch](https://raw.githubusercontent.com/pw4ever/awesome-wm-config/master/00patch/v3.5.4/awful-tag.patch).
* [Arch Linux PKGBUILD](https://raw.githubusercontent.com/pw4ever/awesome-wm-config/master/00patch/v3.5.4/PKGBUILD).
* [my patched awesome repo](https://github.com/pw4ever/awesome) forked from upstream.

## usage

Take a look at the "rc.lua" configuration file (`$HOME/.config/awesome/rc.lua`; perhaps by pressing the keybinding `[modkey]+c` which will open `rc.lua` with the primary editor---for me, Vim).

Most keybindings are prefixed with the "Modkey." This config associates "Modkey" to X Window's "mod4" . On many machines, this associates the "Super_L" (tip: use `xmodmap` in terminal emulator to verify/change this), which usually translate to the (intuitively) "Windows" key.

Some keybinding requires further input (e.g., rename a tag), which will "grab" the key focus from your application. The `[esc]` key is used to cancel partial input.

### window management

#### restart/quit/info

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+r|restart|"r" for restart; used for apply updated "rc.lua" config file|
|[modkey]+[shift]+q|quit|"q" for quit; used for apply updated "rc.lua" config file|
|[modkey]+\|system info popup||
|[modkey]+[f1]|open help in browser||

#### **layout**

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[space]|change to next layout||
|[modkey]+[shift]+[space]|change to prev layout||

| mouse action | function |
| --- | --- |
|[left button]]|change to next layout|
|[right button]|change to prev layout|
|[scroll up]|change to prev layout|
|[scroll down]|change to next layout|

only the following layouts are enabled

| layout | comment |
| --- | --- |
| floating | allow window stacking; the default |
| tile | tiling with master on the left |
| fair | fair allocation of screen space |
| fullscreen | the focused client fullscreened |
| magnifier | the focused client centered but not fullscreened |

in the floating mode, the following mouse actions *on client window* are enabled

| mouse action | function |
| --- | --- |
|[modkey]+[left button]| move client |
|[modkey]+[right button]| resize client |

#### multiple screens/multi-head/RANDR

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+j|focus on the next screen|"j" is easy to reach|
|[modkey]+[ctrl]+j|focus on the prev screen|"k" is easy to reach|
|[modkey]+o|send client to the other screen||

#### misc

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[f2]|prompt a program to launch|inherited from awesome defaults|
|[modkey]+[f3]|toggle touchpad|depend on `synclient` from `xf86-input-synaptics`|
|[modkey]+[f4]|prompt Lua code to be eval-ed in awesome|inherited from awesome defaults|
|[modkey]+c|edit "rc.lua" with the primary editor|"c" for configuration file|
|[modkey]+/|show main menu||
|[modkey]+`|launch screen saver/locker||
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
|[modkey]+p|view previous tag|"p" for previous|
|[modkey]+n|view next tag|"n" for next|
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
|[modkey]+s|toggle sticky status||
|[modkey]+,|toggle horizontal maximized status||
|[modkey]+.|toggle vertical maximized status||
|[modkey]+[|**decrease opacity by 10%**|need composite manager, e.g., xcompmgr|
|[modkey]+]|**increase opacity by 10%**|need composite manager, e.g., xcompmgr|
|[modkey]+[shift]+[|**disable composite manager**||
|[modkey]+[shift]+]|**enable composite manager**||

#### change focus

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+j|focus on the next client in current tag|"j" is easy to reach|
|[modkey]+k|focus on the prev client in current tag|"k" is easy to reach|
|[modkey]+[tab]|focus on the last-focus client in current tag||
|[modkey]+u|jump to the urgent client|"u" for urgent|

#### swap order/select master

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[ctrl]+[enter]|select current client as the master|master is featured on the screen|
|[modkey]+[shift]+j|swap current client with the next one|"j" is easy to reach|
|[modkey]+[shift]+k|swap current client with the prev one|"k" is easy to reach|

#### move/copy to tag

all these keys work on the single **currently focused client**

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[shift]+p|send the client to the previous tag|"p" for previous|
|[modkey]+[shift]+n|send the client to the next tag|"n" for next|
|[modkey]+[shift]+g|**move the client to the named tag**|with tag name completion by [tab]|
|[modkey]+[ctrl]+[shift]+g|**toggle the named tag for the client**|with tag name completion by [tab]|
|[modkey]+[shift]+[1-9,0]|**move the client to {first-ninth, tenth} tag**|prompt for "add a new tag" if not already existed|
|[modkey]+[ctrl]+[shift]+[1-9,0]|**toggle the {first-ninth, tenth} tag for the client**|prompt for "add a new tag" if not already existed|

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

#### misc

| key combo | function | comment |
| --- | --- | --- |
|[modkey]+[shift]+`| toggle the visibility of current client's titlebar | |

### app bindings

shortcut keys are bound for most common apps; the keybinding is designed to be balanced between the left (pressing the [modkey]) and the right hand (an additional easy to reach key).

#### admin

| key combo | app | my choice |
| --- | --- | --- |
|[modkey]+[alt]+[enter] | root terminal | gksudo sakura |
|[modkey]+` | screen saver/locker | xscreensaver |
|[modkey]+' | GUI appfinder | xfce4-appfinder |

#### everyday

| key combo | app | my choice |
| --- | --- | --- |
|[modkey]+[alt]+l| file manager | pcmanfm |
|[modkey]+[enter]| user terminal | sakura |
|[modkey]+[alt]+p| remote terminal | putty |
|[modkey]+[alt]+r| remote terminal | remmina |
|[modkey]+i| primary editor | gvim |
|[modkey]+[shift]+i| secondary editor | emacs |
|[modkey]+b| primary browser | chromium |
|[modkey]+[shift]+b| secondary browser | firefox |
|[modkey]+[alt]+v| secondary browser | virtualbox |
|[modkey]+[shift]+/| screen magnifier | kmag |
|PrintScreen| screen shooter | xfce4-screenshooter |

#### the rest

* currently optimized for [Thinkpad W530 keyboard layout](http://shop.lenovo.com/us/en/laptops/thinkpad/w-series/w530/) ![](http://www.lenovo.com/images/OneWebImages/SubSeries/gallery/laptops/ThinkPad-W530-Laptop-PC-Overhead-Keyboard-View-gallery-940x529.jpg)
* take a look at [the config](https://github.com/pw4ever/awesome-wm-config/blob/master/rc.lua) for details.

### tag list

| mouse action | function |
| --- | --- |
|[left button]|view the tag|
|[modkey]+[left button]|move current client to the tag|
|[right button]|toggle whether to view the tag|
|[modkey]+[right button]|toggle the tag for current client|
|[scroll up]|view the prev tag|
|[scroll down]|view the next tag|

### task list

| mouse action | function |
| --- | --- |
|[left button]|toggle task minimize status|
|[right button]|menu of all tasks across tags|
|[scroll up]|focus on prev task|
|[scroll down]|focus on next task|

### root window/"the desktop"

| mouse action | function |
| --- | --- |
|[right button]|show main menu|
|[scroll up]|view the prev tag|
|[scroll down]|view the next tag|

### window/task/client title bar

| mouse action | function |
| --- | --- |
|[left button]|move the window|
|[right button]|resize the window|

the five buttons on the upper right corner

| button (fromt left to right) | function | 
| --- | --- |
|1| toggle floating status |
|2| toggle maximized status |
|3| toggle sticky/show-in-all-tags status |
|4| toggle always-on-top status |
|5| close window |

## customization

The items can be changed with `awesome-client`. Example:

```lua
customization.option.wallpaper_change_p=true -- enable random wallpaper choosing
customization.timer.change_wallpaper.timeout=7.5 -- choose a wallpaper every 7.5 seconds
```

| value | type | meaning | default value |
| --- | --- | --- | --- |
|customization.option.wallpaper_change_p|boolean|random wallpaper choosing enabled?|true|
|customization.timer.change_wallpaper.timeout|number|randomly choose a wallpaper from the "wallpaper" directory after every *this number of* seconds|15|

## todo

- [ ] improve persistent dynamic tagging: preserve tag configuration (e.g., layout style and client positions)

[awesome]: http://awesome.naquadah.org/
[archlinux]: https://www.archlinux.org/
[lua]: http://www.lua.org/
[awesome dynamic tag regression]: https://github.com/awesomeWM/awesome/commit/9c69e857edb6690fe5a496e82ec57a0bbae36702
[awesome v3.5.2]: https://github.com/awesomeWM/awesome/commit/8125cda2a858708ec98642b30cf59a26d6b39831
[awesome v3.5.3]: https://github.com/awesomeWM/awesome/commit/2321b0b6c56fff2f6ac019820770fb952e1d1dc1
[awesome v3.5.4]: https://github.com/awesomeWM/awesome/commit/2f7d58afceb4e68005bdf3c1fbaad52686581dd7
