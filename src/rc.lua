local awful = require("awful")
local awmd = require("awmd")

-- TODO: default commands should be moved to awmd, awful should not be
-- required here

terminal = "gnome-terminal"
search_cmd = "nautilus"
system_monitor = 'gnome-system-monitor'
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor
lock = "i3lock-fancy -b=20x20"

awful.util.terminal = terminal
awful.util.tagnames = { " 1 ", " 2 ", " 3 ", " 4 " }
awful.util.modkey = 'Mod4'


-- awmd initialization

awmd.initializeTheme()
awmd.enableExtension("alttab_window_switcher")
awmd.enableExtension("application_launcher")
awmd.initializeEnabledExtensions()
awful.screen.connect_for_each_screen(function(s) 
    awmd.onScreenInit(s)
end)

--- end of awmd initialization



-------------------------------------------------------------------
--- 8<  the code below must be moved to amwd ext / defaults  >8 ---

local gears = require("gears")
local beautiful = require("beautiful")
local naughty = require("naughty")

modkey = awful.util.modkey

-- {{{ Helper functions
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () beautiful.menu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}


-- {{{ Key bindings

globalkeys = awmd.getGlobalKeys()
clientkeys = awmd.getClientKeys()

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))


-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

	{ rule = { class = "Plank" },
	  properties = {
		  border_width = 0,
		  floating = true,
		  sticky = true,
		  ontop = true,
		  focusable = false,
		  below = false,
          screen = awful.screen.preferred
	  }
	},

	{ rule = { class = "Synapse" },
	  properties = {
		  border_width = 0,
		  floating = true,
		  sticky = true,
		  ontop = true,
		  focusable = false,
		  below = false,
          placement = awful.placement.centered,
          screen = awful.screen.preferred,
	  }
	},


    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

function get_visible_and_tiled_windows(screen)
    local visible_clients = screen.tiled_clients
    return visible_clients
end

function handle_borders_when_client_shows(c)
    local visible_clients = get_visible_and_tiled_windows(c.screen)
    if #visible_clients > 1 then
        for _, x in pairs(visible_clients) do
            x.border_width = beautiful.border_width
        end
    else
        c.border_width = 0
    end
end

function handle_borders_when_client_hides(c)
    local visible_clients = get_visible_and_tiled_windows(c.screen)
    if #visible_clients == 1 then
        visible_clients[1].border_width = 0
    end
end

client.connect_signal("manage", handle_borders_when_client_shows)
client.connect_signal("raised", handle_borders_when_client_shows)
client.connect_signal("unmanage", handle_borders_when_client_hides)
client.connect_signal("lowered", handle_borders_when_client_hides)
client.connect_signal("property::minimized", handle_borders_when_client_hides)
client.connect_signal("swapped", handle_borders_when_client_hides)
client.connect_signal("swapped", handle_borders_when_client_shows)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- TODO: autostart should be moved to awmd

require("autostart")
