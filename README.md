awesome-wm-config
=================

My customized, self-contained configuration for awesome window manager.

overview
-----

[awesome][] is awesome. But customize it to taste takes time. This is to save the time.

patch
-----

Known to work with *awesome v3.5.2 (The Fox).*

An [upstream bug report][] is filed to address dynamic tagging regression in v3.5.3 and v3.5.4.

patch against v3.5.4 (and Arch Linux PKGBUILD) can be found in this repo under 00patch/v3.5.4/

usage
-----

Clone to `$HOME/.config/awesome`

```bash
cd $HOME/.config && git clone https://github.com/pw4ever/awesome-wm-config.git awesome
```

feature
-----

* *persistent dynamic tagging* across (both regular and randr-induced) restarts

* confirmation before quit/restart to minimize data loss accidents

* keyboard optimize for Arch Linux over Thinkpad W530 

* quick launch of common applications

* cycle through only the most sensible layouts

[awesome]: http://awesome.naquadah.org/wiki/Main_Page "awesome wm wiki"
[upstream bug report]: https://awesome.naquadah.org/bugs/index.php?do=details&task_id=1249&project=1&order=dateopened&sort=desc
