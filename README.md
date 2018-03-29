<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [[awesome Window Manager][awesome] configuration](#awesome-window-managerawesome-configuration)
  - [intro](#intro)
  - [setup](#setup)
    - [install on Linux](#install-on-linux)
    - [dependencies](#dependencies)
    - [miscellaneous](#miscellaneous)
  - [usage](#usage)
    - [**universal argument**](#universal-argument)
    - [window management](#window-management)
      - [restart/quit/info](#restartquitinfo)
      - [**layout**](#layout)
      - [multiple screens/multi-head/RANDR](#multiple-screensmulti-headrandr)
      - [misc](#misc)
    - [**persistent dynamic tagging**](#persistent-dynamic-tagging)
      - [tag persistence](#tag-persistence)
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

Please use the branch that **matches your Awesome version**:
* [Awesome 3.x](https://github.com/pw4ever/awesome-wm-config/tree/awesome-3.x).
* [Awesome 4.x](https://github.com/pw4ever/awesome-wm-config/tree/awesome-4.x).

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
* [Emacs-inspired universal argument](#universal-argument): Specify a numeric argument for, e.g., repetition or precise resizing. Idea/prototype credit: @AnthonyAaronHughWong in #3.
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

* Install [awesome][awesome] with your preferred package manager. Example: `sudo pacman -S awesome --needed --noconfirm` on [Arch Linux][archlinux].
* Clone this repo to `$HOME/.config/awesome`.
```bash
cd $HOME/.config && git clone https://github.com/pw4ever/awesome-wm-config.git awesome
```
* Setup .xinitrc or Display Manager accordingly.

### dependencies

These dependencies are mostly derived from the application keybindings. Some are needed to enable basic features like theming (`feh`), [Desktop Entry Specification](http://standards.freedesktop.org/desktop-entry-spec/latest/)-style autostart (`dex`), audio setup (`alsa-utils`), backlight (`xorg-xbacklight`), Webcam (`cheese`), music player (`mpd` and `mpc`), screen lock (`xscreensaver`), network management (`network-manager-applet`), terminal (`sakura`), task manager (`lxtask`), and screen setup (`arandr`), etc..

On [Arch Linux][archlinux]:

```bash
sudo pacman -S --needed --noconfirm feh dex xdg-utils screenfetch scrot xcompmgr kdeaccessibility wmname gnome-keyring seahorse
sudo pacman -S --needed --noconfirm alsa-utils pavucontrol xorg-xbacklight xf86-input-synaptics cheese mpd mpc workrave
sudo pacman -S --needed --noconfirm xscreensaver networkmanager network-manager-applet mate-power-manager arandr xfce4-appfinder xfce4-screenshooter gnome-control-center lxtask
sudo pacman -S --needed --noconfirm pcmanfm gvfs udiskie lxsession lxappearance xarchiver
sudo pacman -S --needed --noconfirm sakura terminator conky gksu launchy
sudo pacman -S --needed --noconfirm gvim emacs firefox chromium putty zeal remmina synergy
sudo pacman -S --needed --noconfirm fcitx-im fcitx-googlepinyin fcitx-configtool
```

### miscellaneous

* populate your `$HOME/.config/autostart` with [Desktop Entry Specification](http://standards.freedesktop.org/desktop-entry-spec/latest/)-style autostart files (optionally with `OnlyShowIn=awesome` if you only want them to auto-start in [awesome][awesome]).
* [my autostart setup can be found here](https://github.com/pw4ever/awesome-wm-config/tree/master/autostart).

## usage

Take a look at the "rc.lua" configuration file (`$HOME/.config/awesome/rc.lua`; perhaps by pressing the keybinding <kbd>Modkey</kbd><kbd>c</kbd> which will open `rc.lua` with the primary editor---for me, Vim).

Most keybindings are prefixed with the <kbd>Modkey</kbd>. This config associates <kbd>Modkey</kbd> to X Window's <kbd>Mod4</kbd>. On many machines, this associates the <kbd>Super_L</kbd> (tip: use `xmodmap` in terminal emulator to verify/change this), which usually translate to the (intuitively) <kbd>Windows</kbd> key.

Some keybinding requires further input (e.g., rename a tag), which will grab the key focus from your application. The <kbd>Esc</kbd> key is used to cancel partial input.

### **universal argument**

Universal Argument (UniArg), inspired by the [namesake Emacs feature](https://www.gnu.org/software/emacs/manual/html_node/emacs/Arguments.html), supplies a positive numeric argument to the following command. Depending on the context, it may supply a number of repetitions (search for `uniarg:key_repeat` in `rc.lua`) or a numeric argument (search for `uniarg:key_numarg` in `rc.lua`) such as percentage of volume adjustment or pixels to resize the client window.   For example, with the UniArg being 3, "open terminal" operation (<kbd>Modkey</kbd><kbd>Enter</kbd> by default) will open 3 terminals.

Universal argument is activated when inputing a great-than-1 integer, and is deactivated when inputing a less-than-2 integer or a non-number. When universal argument is deactivated, the default behavior kicks in, which follows some heuristics to do sensible things such as the "extend client by 1/7 of the margin" and "shrink client by 1/11 of client width and leave client width at least 50 pixels" behavior for client window side expansion/shrinking documented below.

There are two modes of universal argument: Regular and persistent. Regular universal argument only applies to the next operation, while persistent universal argument applies to all following operations until changed or deactivated.

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>u</kbd>|prompt for universal argument|see above paragraphs for details|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>u</kbd>|prompt for persistent universal argument|see above paragraphs for details|

### window management

#### restart/quit/info

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>r</kbd>|restart|"r" for restart; used for apply updated "rc.lua" config file|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>r</kbd>|restart|"r" for restart; restart without confirming with user|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>q</kbd>|quit|"q" for quit; exit the current Awesome session|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>Ctrl</kbd><kbd>q</kbd>|forcibly quit|"q" for quit; quit without confirming with user|
|<kbd>Modkey</kbd><kbd>\\</kbd>|system info popup||
|<kbd>Modkey</kbd><kbd>f1</kbd>|open help in browser||
|<kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>Esc</kbd>|open task manager|lxtask|

#### **layout**

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Space</kbd>|change to next layout||
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>Space</kbd>|change to prev layout||

| mouse action | function |
| --- | --- |
|<kbd>left button</kbd>|change to next layout|
|<kbd>right button</kbd>|change to prev layout|
|<kbd>scroll up</kbd>|change to prev layout|
|<kbd>scroll down</kbd>|change to next layout|

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
|<kbd>Modkey</kbd><kbd>left button</kbd>| move client |
|<kbd>Modkey</kbd><kbd>right button</kbd>| resize client |

#### multiple screens/multi-head/RANDR

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>j</kbd>|focus on the next screen|"j" is easy to reach|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>k</kbd>|focus on the prev screen|"k" is easy to reach|
|<kbd>Modkey</kbd><kbd>o</kbd>|send client to the other screen||
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>o</kbd>|send tag to next screen||
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>o</kbd>|send tag to prev screen||
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>\\</kbd>|select next display arrangement|<https://awesomewm.org/recipes/xrandr/>|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Alt</kbd><kbd>\\</kbd>|XRandR config popup|<https://github.com/k3rni/foggy>|

#### misc

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>f2</kbd>|prompt a program to launch|inherited from awesome defaults|
|<kbd>Modkey</kbd><kbd>r</kbd>|prompt a program to launch|"r" for run|
|<kbd>Modkey</kbd><kbd>f3</kbd>|toggle touchpad|depend on `synclient` from `xf86-input-synaptics`|
|<kbd>Modkey</kbd><kbd>f4</kbd>|prompt Lua code to be eval-ed in awesome|inherited from awesome defaults|
|<kbd>Modkey</kbd><kbd>c</kbd>|edit "rc.lua" with the primary editor|"c" for configuration file|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>/</kbd>|show main menu||
|<kbd>Modkey</kbd><kbd>x</kbd>|show main menu|MSFT Windows key| 
|<kbd>Modkey</kbd><kbd>X</kbd>|show main menu|MSFT Windows key|
|<kbd>Modkey</kbd><kbd>;</kbd>|toggle task action menu|| 
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>;</kbd>|toggle tag action menu||
|<kbd>Modkey</kbd><kbd>'</kbd>|choose from clients on current tag|| 
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>'</kbd>|prompt to choose from clients on current tag|| 
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>'</kbd>|choose from all clients||
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>Ctrl</kbd><kbd>'</kbd>|prompt to choose from all clients||
|<kbd>Modkey</kbd><kbd>`</kbd>|lock screen with screensaver||
|<kbd>Modkey</kbd><kbd>Enter</kbd>|launch user terminal||
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Enter</kbd>|launch root terminal||

### **persistent dynamic tagging**

#### tag persistence

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Alt</kbd><kbd>t</kbd>|toggle tag persistence|tags persist across exit/restart by default|

#### **add/delete/rename**

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>a</kbd>|create a new tag after the current one and view it|"a" for add|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>a</kbd>|create a new tag before the current one and view it|"a" for add|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>d</kbd>|delte the current tag *if there is no client on it*|"d" for delete|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>r</kbd>|rename the current tag|"r" for rename|

#### view

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>p</kbd>|view previous tag|"p" for previous|
|<kbd>Modkey</kbd><kbd>n</kbd>|view next tag|"n" for next|
|<kbd>Modkey</kbd><kbd>z</kbd>|view last tag||
|<kbd>Modkey</kbd><kbd>g</kbd>|**prompted for a tag to view**|with tag name completion with <kbd>Tab</kbd>|
|<kbd>Modkey</kbd>+[1-9,0]|**view the first-ninth, tenth tag**|prompt for "add a new tag" if not already existed|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd>+[1-9,0]|**view also the first-ninth, tenth tag**|prompt for "add a new tag" if not already existed|

#### move

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>p</kbd>|move the current tag backward by 1 position||
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>n</kbd>|move the current tag forward by 1 position||

### client management

#### operation

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>c</kbd>|kill focused client||
|<kbd>Alt</kbd><kbd>f4</kbd>|kill focused client|MSFT Windows key|
|<kbd>Modkey</kbd><kbd>f</kbd>|toggle fullscreen status|hides statusbar|
|<kbd>Modkey</kbd><kbd>m</kbd>|toggle maximized status|leaves statusbar visible|
|<kbd>Modkey</kbd><kbd>Left</kbd>|move window to left half screen|leaves statusbar visible|
|<kbd>Modkey</kbd><kbd>Right</kbd>|move window to right half screen|leaves statusbar visible|
|<kbd>Modkey</kbd><kbd>Up</kbd>|move window to top half screen|leaves statusbar visible|
|<kbd>Modkey</kbd><kbd>Down</kbd>|move window to bottom half screen|leaves statusbar visible|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Left</kbd>|extend client to the left|by 1/7 of the margin|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Right</kbd>|extend client to the right|by 1/7 of the margin|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Up</kbd>|extend client to the top|by 1/7 of the margin|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Down</kbd>|extend client to the bottom|by 1/7 of the margin|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>Left</kbd>|shrink client from right|by 1/11 of client width; leave client width at least 50 pixels|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>Right</kbd>|shrink client from left|by 1/11 of client width; leave client width at least 50 pixels|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>Up</kbd>|shrink client from bottom|by 1/11 of client height; leave client height at least 50 pixels|
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Shift</kbd><kbd>Down</kbd>|shrink client from top|by 1/11 of client height; leave client height at least 50 pixels|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>m</kbd>|minimize|minimized client need mouse click on tasklist to restore|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Space</kbd>|toggle floating status||
|<kbd>Modkey</kbd><kbd>t</kbd>|toggle ontop status||
|<kbd>Modkey</kbd><kbd>s</kbd>|toggle sticky status||
|<kbd>Modkey</kbd><kbd>,</kbd>|toggle horizontal maximized status||
|<kbd>Modkey</kbd><kbd>.</kbd>|toggle vertical maximized status||
|<kbd>Modkey</kbd><kbd>[</kbd>|**decrease opacity by 10%**|need composite manager, e.g., xcompmgr|
|<kbd>Modkey</kbd><kbd>]</kbd>|**increase opacity by 10%**|need composite manager, e.g., xcompmgr|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>[</kbd>|**disable composite manager**||
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>]</kbd>|**enable composite manager**||

#### change focus

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>j</kbd>|focus on the next client in current tag|"j" is easy to reach|
|<kbd>Modkey</kbd><kbd>Tab</kbd>|focus on the next client in current tag|MSFT Windows key|
|<kbd>Modkey</kbd><kbd>k</kbd>|focus on the prev client in current tag|"k" is easy to reach|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>Tab</kbd>|focus on the prev client in current tag|MSFT Windows key|
|<kbd>Modkey</kbd><kbd>y</kbd>|jump to the urgent client|"y" next to "u" (taken by universal argument) for urgent|

#### swap order/select master

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Enter</kbd>|select current client as the master|master is featured on the screen|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>j</kbd>|swap current client with the next one|"j" is easy to reach|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>k</kbd>|swap current client with the prev one|"k" is easy to reach|

#### move/copy to tag

all these keys work on the single **currently focused client**

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>p</kbd>|send the client to the previous tag|"p" for previous|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>n</kbd>|send the client to the next tag|"n" for next|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>g</kbd>|**move the client to the named tag**|with tag name completion by <kbd>Tab</kbd>|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>g</kbd>|**toggle the named tag for the client**|with tag name completion by <kbd>Tab</kbd>|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>1-9,0</kbd>|**move the client to {first-ninth, tenth} tag**|prompt for "add a new tag" if not already existed|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>Shift</kbd><kbd>1-9,0</kbd>|**toggle the {first-ninth, tenth} tag for the client**|prompt for "add a new tag" if not already existed|

#### change space allocation in **tile** layout

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>=</kbd>|reset master width to 50%|"=" for equal partition of screen|
|<kbd>Modkey</kbd><kbd>l</kbd>|increase master width by 5%|"l" towards right on keyboard|
|<kbd>Modkey</kbd><kbd>h</kbd>|decrease master width by 5%|"h" towards left on keyboard|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>l</kbd>|increase number of masters by 1|"l" towards right on keyboard|
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>h</kbd>|decrease number of masters by 1|"h" towards left on keyboard|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>l</kbd>|increase number of columns by 1|"l" towards right on keyboard|
|<kbd>Modkey</kbd><kbd>Ctrl</kbd><kbd>h</kbd>|decrease number of columns by 1|"h" towards left on keyboard|

#### misc

| key combo | function | comment |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>`</kbd>| toggle the visibility of current client's titlebar | |

### app bindings

shortcut keys are bound for most common apps; the keybinding is designed to be balanced between the left (pressing the <kbd>Modkey</kbd>) and the right hand (an additional easy to reach key).

#### admin

| key combo | app | my choice |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Enter</kbd> | root terminal | gksudo sakura |
|<kbd>Modkey</kbd><kbd>`</kbd> | screen saver/locker | xscreensaver |
|<kbd>Modkey</kbd><kbd>Home</kbd> | screen saver/locker | xscreensaver |
|<kbd>Modkey</kbd><kbd>End</kbd> | suspend | systemctl suspend |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>Home</kbd> | hibernate (will confirm) | systemctl hibernate |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>End</kbd> | hybrid sleep (will confirm) | systemctl hybrid-sleep |
|<kbd>Modkey</kbd><kbd>Insert</kbd> | reboot (will confirm) | systemctl reboot |
|<kbd>Modkey</kbd><kbd>Delete</kbd> | power off (will confirm) | systemctl poweroff |
|<kbd>Modkey</kbd><kbd>/</kbd> | GUI appfinder | xfce4-appfinder |

#### everyday

| key combo | app | my choice |
| --- | --- | --- |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>l</kbd>| file manager | pcmanfm |
|<kbd>Modkey</kbd><kbd>e</kbd>| file manager | pcmanfm; MSFT Windows key |
|<kbd>Modkey</kbd><kbd>E</kbd>| file manager | pcmanfm; MSFT Windows key |
|<kbd>Modkey</kbd><kbd>Enter</kbd>| user terminal | sakura |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>p</kbd>| remote terminal | putty |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>r</kbd>| remote terminal | remmina |
|<kbd>Modkey</kbd><kbd>i</kbd>| primary editor | gvim |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>i</kbd>| secondary editor | emacs |
|<kbd>Modkey</kbd><kbd>b</kbd>| primary browser | chromium |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>b</kbd>| secondary browser | firefox |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>v</kbd>| secondary browser | virtualbox |
|<kbd>Modkey</kbd><kbd>Alt</kbd><kbd>z</kbd>| doc viewer | zeal |
|<kbd>Modkey</kbd><kbd>Shift</kbd><kbd>\\</kbd>|screen magnifier | kmag |
|<kbd>PrtSc</kbd>| screen shooter | xfce4-screenshooter |

#### the rest

* currently optimized for [Thinkpad W530 keyboard layout](http://shop.lenovo.com/us/en/laptops/thinkpad/w-series/w530/) ![](http://www.lenovo.com/images/OneWebImages/SubSeries/gallery/laptops/ThinkPad-W530-Laptop-PC-Overhead-Keyboard-View-gallery-940x529.jpg)
* take a look at [the config](https://github.com/pw4ever/awesome-wm-config/blob/master/rc.lua) for details.

### tag list

| mouse action | function |
| --- | --- |
|<kbd>left button</kbd>|view the tag|
|<kbd>Modkey</kbd><kbd>left button</kbd>|move current client to the tag|
|<kbd>middle button</kbd>|toggle whether to view the tag|
|<kbd>Modkey</kbd><kbd>middle button</kbd>|toggle the tag for current client|
|<kbd>right button</kbd>|show tag action menu|
|<kbd>Modkey</kbd><kbd>right button</kbd>|delete the tag if empty|
|<kbd>scroll up</kbd>|view the prev tag|
|<kbd>scroll down</kbd>|view the next tag|

### task list

| mouse action | function |
| --- | --- |
|<kbd>left button</kbd>|toggle task minimize status|
|<kbd>middle button</kbd>|choose from clients on current tag|
|<kbd>Modkey</kbd><kbd>middle button</kbd>|choose from all clients|
|<kbd>right button</kbd>|show task action menu|
|<kbd>scroll up</kbd>|focus on prev task|
|<kbd>scroll down</kbd>|focus on next task|

### root window/"the desktop"

| mouse action | function |
| --- | --- |
|<kbd>left button</kbd>|choose from all clients|
|<kbd>middle button</kbd>|show tag action menu|
|<kbd>right button</kbd>|show main menu|
|<kbd>scroll up</kbd>|view the prev tag|
|<kbd>scroll down</kbd>|view the next tag|

### window/task/client title bar

| mouse action | function |
| --- | --- |
|<kbd>left button</kbd>|move the window|
|<kbd>right button</kbd>|resize the window|

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
|`customization.option.wallpaper_change_p`|boolean|random wallpaper choosing enabled?|`true`|
|`customization.timer.change_wallpaper.timeout`|number|randomly choose a wallpaper from the "wallpaper" directory after every *this number of* seconds|`15`|
|`customization.option.tag_persistent_p`|boolean|tag persistent across restart? `false` for clean slate|`true`|
|`customization.option.low_battery_notification_p`|boolean|warn about low battery condition|`true`|
|`customization.widgets.bat.warning_threshold`|number|low battery notification threshold in percentage|`10`|
|`customization.widgets.bat.instance`|string|battery under monitor for low battery notification|`"BAT0"`|

## todo

- [ ] improve persistent dynamic tagging: preserve tag configuration (e.g., layout style and client positions)

[awesome]: http://awesome.naquadah.org/
[archlinux]: https://www.archlinux.org/
[lua]: http://www.lua.org/
[awesome dynamic tag regression]: https://github.com/awesomeWM/awesome/commit/9c69e857edb6690fe5a496e82ec57a0bbae36702
[awesome v3.5.2]: https://github.com/awesomeWM/awesome/commit/8125cda2a858708ec98642b30cf59a26d6b39831
[awesome v3.5.3]: https://github.com/awesomeWM/awesome/commit/2321b0b6c56fff2f6ac019820770fb952e1d1dc1
[awesome v3.5.4]: https://github.com/awesomeWM/awesome/commit/2f7d58afceb4e68005bdf3c1fbaad52686581dd7
