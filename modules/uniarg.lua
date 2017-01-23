--
-- Emacs-like universal argument, i.e., numeric prefix
-- Ref: http://www.gnu.org/software/emacs/manual/html_node/emacs/Arguments.html
-- Proposed by: AnthonyAaronHughWong (https://github.com/AnthonyAaronHughWong)
--

package.path = package.path .. ";./?/init.lua;"

local awful = require("awful")
awful.key = require("awful.key")
awful.screen = require("awful.screen")

local math = require("math")

local uniarg = {
    active = false,
    arg = 1
}

function uniarg:init (textbox)
    self.active = false
    self.persistent = false
    self.arg = 1
    self.textbox = textbox
end

function uniarg:reset ()
    self.active = false
    self.arg = 1
end

function uniarg:set (arg)
    arg = tonumber(arg)
    if arg <= 0 then
        self.arg = 1
    else
        self.arg = arg
    end
end

function uniarg:update_textbox ()
    local textbox = self.textbox[awful.screen.focused()]
    if self.active then
        textbox.markup = ('<span fgcolor="red" weight="bold"> UniArg: ' .. self.arg .. ' </span>')
    else
        textbox.text = ""
    end
end

function uniarg:activate ()
    self.active = true
    uniarg:update_textbox()
end

function uniarg:deactivate ()
    self.active = false
    self.persistent = false
    uniarg:update_textbox()
end

function uniarg:key_repeat (mod, key, callback)
    return awful.key(mod, key,
    function (...)
        if self.active then
            for _ = 1, self.arg do
                callback(...)
            end
        else
            callback(...)
        end
        if not self.persistent then
            self:deactivate()
        end
    end
    )
end

function uniarg:key_numarg (mod, key, callback_regular, callback_numarg)
    return awful.key(mod, key,
    function (...)
        if self.active and callback_numarg then
            callback_numarg(self.arg, ...)
        else
            callback_regular(...)
        end
        if not self.persistent then
            self:deactivate()
        end
    end
    )
end

return uniarg
