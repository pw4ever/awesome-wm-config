Contributing Obvious Widgets
============================

So, you want to contribute to the Obvious project? Well of course you do! I
guess that's pretty clear. I mean, anyone could tell, right? Obviously.

...

So lets get started.

Patching An Existing Widget
---------------------------

If you want to just improve our existing widgets by adding settings and
features, it's pretty easy. Some things to watch out for:
 - Style! Make sure that the code you write fits with the general style of the
   widget. In particular, you should use the same indentation pattern that the
   code uses. Also, trailing whitespace is bad. Try to avoid adding space at
   the ends of lines. This wastes bytes and is considered poor form. Anyway,
   you probably get the idea.
 - Clarity. Your code should be easy to understand, maintainable, and
   modularized. You should also avoid code duplication wherever possible by
   adding functions. If something is unclear, and you can't write it in such a
   way that it will be clear, explain it with a comment.
 - Regressions. Please _test_ your changes before submitting to make sure that
   not only they work, but have not broken other parts of the widget!
 - Options. If you add or remove options, make sure the top-level README file
   reflects the changes. See "Adding A New Widget"'s section on this.

Adding A New Widget
-------------------

It's also understandable that people want to add their own widgets to the
Obvious repository. That's fantastic. Adding your useful widgets to Obvious
makes them available for everyone. However, there are a few things that you
need to know about the structure of Obvious. Note that a lot of the stuff from
the section "Patching An Existing Widget" also apply here.

### File Structure

    obvious
    |
    |-- init.lua
    |
    |-- battery
    |   |
    |   |-- init.lua
    |   `-- readme
    .

In general, Obvious widgets are laid as above. The main file, obvious/init.lua
has the definition of the Obvious module in general. When adding a new widget,
you want to also add it to this file. The name that you want to add is the same
as the folder you'll be making.

Then, you want to make that folder. In the example above, that is "battery".
Inside the folder, you want to have at least "init.lua" and "readme". The
init.lua file will be run first, the readme explains to the user what your
module does and how to implement it, as well as any settings. Feel free to add
more .lua files in the folder if you need them.

### Your init.lua

This is your main file for your widget. Add other files if necessary for the
sake of organization, but this is all you really need. Refer to other modules
and documentation for how to write this kind of file. In general, the structure
is:

* Get variables and modules from the rc.lua and Awesome
* Declare your module
* Write your code using the variables defined
* Write your public settings interface (see below)

### Your settings

For settings, we have the standard that your module must have a collection of
functions named `set_<setting>`. These are the access to the module's settings
and can otherwise be whatever you want.

These then are used from the rc.lua like:

    obvious.module.set_something(foo)

And that should be all it takes for the user.

### Your data

If the widget gathers nontrivial data (i.e. wlan signal strength, battery charge,
but _not_ the current time, as that's just one function call away), you should
supply a function called `get_data()` which returns nil on failure and a hashtable
with the collected data otherwise. This is so other people can build on your work
(the true spirit of open source, right? :P) and create different ways of visualizing
the data gathered by your widget without duplicating code (which is why your widget
should also use the `get_data()` function).

### Top-level init file

If someone does `require("obvious")`, the behaviour is to import all widgets.
The way this is accomplished is by making an "obvious" module that requires
all of the sub-modules. In short, if you've created a new sub-module, you
should add your sub-module to the list of things that is required by the
init.lua in the root folder.

### Top-level README

The top-level README is an overview of what features each widget sub-module
supports and provides. It is a listing of the options available and what
views it supports (like text-only, progress bar, etc.). When creating a new
widget, you should add your overview to the top-level README.

### Your readme

Your "readme" is the explanation for the user. As such, it has a rough layout:

* Widget Name
* Description of widget.
* Explanation of available settings.
* Explanation of how to integrate it into your rc.lua.

The exact way you do this doesn't matter, but please try to stick to this kind
of ordering/layout.

Submitting Your Changes
-----------------------

Once you've written a tidy, well-fitting, clear patch with no bugs, you should
submit it. We'd seriously love to have it. Some ways:
* Commit it and use git-format-branch to create a patch-email. Then send this
  e-mail to one of the developers of obvious if you can find their e-mails, or
  to one of the awesome mailing lists which we tend to read. We then can take
  it, read it, possibly reply to it with suggestions for improvement, or apply
  it to the obvious project.
* You can put your changes into your own personal git repo on the web and
  request a pull. Use the command git request-pull for this. This makes a bit
  of formatted text that tells us what changes you've made and where to get
  it. Again, e-mail this text up to us somewhere.
* Also, we're generally pretty laid back. If we know you, trust you to write
  decent code, and know that you want to help regularly, we can probably just
  agree to give you commit access to the main Obvious repo.
