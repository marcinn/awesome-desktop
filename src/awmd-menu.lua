local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")

local hotkeys_popup = require("awful.hotkeys_popup").widget

-- local awesome = require("awesome")


local awesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "restart", awesome.restart },
   { "quit", "gnome-session-quit --logout --force" },
   { "shutdown", function () awful.spawn.with_shell("~/bin/awmd-logout") end },
}

local desktopmenu = {
   { "Change background", "gnome-control-center background"},
   { "Display settings...", "gnome-control-center display"},
   { "Settings...", "gnome-control-center"}
}


-- high level API for menu (future)
local menu_api = {
    get_desktop_menu = function()
        local items = gears.table.join({}, desktopmenu)
        table.insert(items, 1, {"AwesomeWM", awesomemenu, beautiful.awesome_icon})
        return awful.menu({items = items})
    end
}

return menu_api
