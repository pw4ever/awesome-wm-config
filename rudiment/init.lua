local awful = require("awful")
local naughty = require("naughty")
rudiment = {}
rudiment.config = {}

rudiment.config.version = "1.6.7"
rudiment.config.help_url = "https://github.com/pw4ever/awesome-wm-config/tree/" .. rudiment.config.version

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
