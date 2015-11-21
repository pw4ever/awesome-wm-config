-- shared config
local awful = require("awful")
local naughty = require("naughty")
local rudiment = {}
rudiment.config = {}


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
rudiment.modkey = "Mod4"



rudiment.config.version = "1.6.7"
rudiment.config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. rudiment.config.version
rudiment.config_path = awful.util.getdir("config")

rudiment.default = {}
rudiment.default.property = {}
rudiment.default.property = {
    layout = awful.layout.suit.floating,
    mwfact = 0.5,
    nmaster = 1,
    ncol = 1,
    min_opacity = 0.01,
    max_opacity = 1,
    default_naughty_opacity = 0.90,
    low_naughty_opacity = 0.90,
    normal_naughty_opacity = 0.95,
    critical_naughty_opacity = 1,
}
rudiment.default.compmgr = 'xcompmgr'
rudiment.default.wallpaper_change_interval = 15
rudiment.option = {}
rudiment.option.wallpaper_change_p = true
naughty.config.presets.low.opacity = rudiment.default.property.low_naughty_opacity
naughty.config.presets.normal.opacity = rudiment.default.property.normal_naughty_opacity
naughty.config.presets.critical.opacity = rudiment.default.property.critical_naughty_opacity
rudiment.naughty = naughty
do
    local tools = {
        terminal = "sakura",
        system = {
            filemanager = "pcmanfm",
        },
        browser = {
        },
        editor = {
        },
    }

    --tools.browser.primary = os.getenv("BROWSER") or "firefox"
    --tools.browser.secondary = ({chromium="firefox", firefox="chromium"})[tools.browser.primary]

    -- alternative: override
    tools.browser.primary = "google-chrome-stable"
    tools.browser.secondary = "firefox"

    --tools.editor.primary = os.getenv("EDITOR") or "gvim"
    --tools.editor.secondary = ({emacs="gvim", gvim="emacs"})[tools.editor.primary]

    -- alternative: override
    tools.editor.primary = "gvim"
    tools.editor.secondary = "emacs"
    rudiment.tools = tools
end
return rudiment
