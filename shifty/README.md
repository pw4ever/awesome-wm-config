# shifty

## Current version information
This is a fork from [bioe007](https://github.com/bioe007/awesome-shifty) shifty library. The main goal of this fork is make
shifty compatible with awesome-3.5

## About
[Shifty](https://awesome.naquadah.org/wiki/Shifty) is an Awesome 3 extension
that implements dynamic tagging.

It also implements fine client matching configuration allowing _you_ to be
the master of _your_ desktop.

Here are a few ways of how shifty makes awesome awesomer:

* on-the-fly tag creation and disposal
* advanced client matching
* easy moving of clients between tags
* tag add/rename prompt in taglist (with completion)
* reordering tags and configurable positioning
* tag name guessing, automagic no-config client grouping
* customizable keybindings per client and tag
* simple yet powerful configuration

## Use

0. Go to configuration directory, usually `~/.config/awesome`
1. Clone repository:

    `git clone https://github.com/cdump/awesome-shifty.git shifty`

2. Move the example `rc.lua` file into your configuration directory.

    `cp shifty/example.rc.lua rc.lua`

3. Restart awesome and enjoy.

There are many configuration options for shifty, the `example.rc.lua` is
provided merely as a starting point. The most important variables are the
tables:

* `shifty.config.tags = {}`
    - Sets predefined tags, which are not necessarily initialized.
* `shifty.config.apps = {}`
    - How to handle certain applications.
* `shifty.config.defaults = {}`
    - Fallback values used when a preset is not found in the first two
    configuration tables.

But for each of these there are _tons_ of shifty variables and settings, its
easiest to check out the wiki page or the module itself.

In the `example.rc.lua` searching for `shifty` in your editor can also help to
make sense of these.

## Development
Report bugs at the [github
repo](https://github.com/cdump/awesome-shifty/issues). Please include at least
the current versions of awesome and shifty, as well as distribution.

## Credits
* [Maxim Andreev](mailto:andreevmaxim@gmail.com)
    - Current 3.5 version fork maintainer
* [Perry Hargrave](mailto:resixian@gmail.com)
    - Maintainer of base version (3.4) that was used for fork.
* [koniu](mailto:gkusnierz@gmail.com)
    - Original author

## License
Current awesome wm license or if thats not defined, GPLv2.
