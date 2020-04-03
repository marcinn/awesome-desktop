local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")

local hotkeys_popup = require("awful.hotkeys_popup").widget

-- local awesome = require("awesome")


local awesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "restart", awesome.restart },
   { "suspend", "systemctl suspend" },
   { "quit", "gnome-session-quit --logout --force" },
   { "shutdown", function () awful.spawn.with_shell("awmd-shutdown") end },
}

local desktopmenu = {
   { "Change background", "gnome-control-center background"},
   { "Display settings...", "gnome-control-center display"},
   { "Settings...", "gnome-control-center"}
}


local completemenu = nil

-- high level API for menu (future)
local menu_api = {
    get_desktop_menu = function()  -- singleton
        if completemenu == nil then
            local completemenuitems = gears.table.join({}, desktopmenu)
            table.insert(completemenuitems, 1, {"AwesomeWM", awesomemenu, beautiful.awesome_icon})
            completemenu = awful.menu({items = completemenuitems})
        end
        return completemenu
    end
}

return menu_api
