local gears = require("gears")
local awful = require("awful")


function git_install(ext)
    awful.spawn("git clone "+ext.url)
end

local synapse_application_launcher = {
    factory = function()
        os.execute("killall -9 synapse")
        os.execute("synapse -s &")
    end
}

local menubar_application_launcher = {
    modulename = 'menubar',
    factory = function(menubar)
        return {
            globalKeys = gears.table.join(
                awful.key(
                    { awful.util.modkey }, "r", function() menubar.show() end,
                    {description = "show the menubar", group = "launcher"}
                )
            ),
            init = function()
                menubar.utils.terminal = awful.util.terminal
            end
        }
    end
}

local known_extensions = {
    alttab_window_switcher = {
        modulename = "awesome-switcher",
        url = "https://github.com/troglobit/awesome-switcher",
        installer = git_install,
        factory = function(module)
            return {
                globalKeys = gears.table.join(
                awful.key({ "Mod1",           }, "Tab",
                function ()
                    module.switch( 1, "Mod1", "Alt_L", "Shift", "Tab")
                end),

                awful.key({ "Mod1", "Shift"   }, "Tab",
                function ()
                    module.switch(-1, "Mod1", "Alt_L", "Shift", "Tab")
                end)
                )
            }
        end
    },
    application_launcher = synapse_application_launcher
}

return known_extensions
