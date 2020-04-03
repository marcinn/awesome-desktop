require("awful.autofocus")

local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local lgi = require("lgi")
local gtk = lgi.require("Gtk")
local gio = lgi.require("Gio")
local gfs = require("gears.filesystem")
local awmd_menu = require("awmd-menu")

local THEMES_PATH = gfs.get_configuration_dir() .. 'themes/'

local extensions = {}
local installable_extensions = {}
local active_extensions = {}
local desktopsettings = {}
local dconfschemas = {}
local awmd_config = {
    commands = {
        terminal = 'gnome-terminal',
        search = 'nautilus',
        system_monitor = 'gnome-system-monitor',
        editor = 'gedit',
        lock = 'awmd-lock',
    },
    tags = {"term", "web", "3", "talk", "5", "6"},
    modkey = 'Mod4',
}
local awmd_object = gears.object { enable_properties = false, class = 'AWMDObject' }

local _desktopsettingschemas = {
    "org.gnome.",
    "org.awmd.",
    "org.awmd.commands",
}

local icontheme = gtk.IconTheme.get_default()

function saveSettings(awmd)
    local s = dconfschemas["org.awmd."]
    s:set_string('modkey', awmd.conf.modkey)
end

function getExtensionsGlobalkeys()
    local keys = {}
    for _, x in pairs(active_extensions) do
        keys = gears.table.join(keys, x.globalKeys)
    end
    return keys
end

function loadExtension(meta)
    if meta.modulename then
        status, module = pcall(require, meta.modulename)
        loaded = status and module or nil
    else
        loaded = true
        module = nil
    end
    if loaded then
        if meta.factory then
            return meta.factory(module)
        else
            return meta
        end
    else
        return nil
    end
end

function loadGnomeDesktopSettingsNew()
    for _, name in pairs(_desktopsettingschemas) do
        local s = gio.Settings.new(name)
        dconfschemas[name] = s
        desktopsettings[schema] = {}
        for __, key in pairs(s:list_keys()) do
            desktopsettings[schema][key] = s:get_string(key)
        end
    end
end

function loadGnomeDesktopSettings()
    for _, schema in pairs(gio.Settings.list_schemas()) do
        local match=false
        for __, name in pairs(_desktopsettingschemas) do
            if schema:match("^"..name) then
                match = true
                break
            end
        end
        local match = true
        if match then
            local s = gio.Settings.new(schema)
            dconfschemas[schema] = s
            desktopsettings[schema] = {}
            for __, key in pairs(s:list_keys()) do
                desktopsettings[schema][key] = s:get_string(key)
            end
        end
    end

end

function updateAWMDConfig()
    -- configure local config based on gnome settings
    local _clockfmt = get_desktop_setting("org.gnome.desktop.interface", "clock-format", "24h")
    if _clockfmt == '24h' then
        awmd_config['clock_format'] = "%a %b %d, %H:%M"
    else
        awmd_config['clock_format'] = "%a %b %d, %l:%M%P"
    end

    gears.table.crush(awmd_config, {
        icon_theme = get_desktop_setting(
        'org.gnome.desktop.interface', 'icon-theme', 'Arc'),
        font_name = get_desktop_setting(
        'org.gnome.desktop.interface', 'font-name', 'Roboto 12')
    })

    awmd_object:emit_signal('config::changed')
end

function installExtension(meta)
    if meta.modulename then
        status, module = pcall(require, meta.modulename)
        if status and module then
            return true  -- it is already installed
        end
    end
    if meta.installer then
        return meta.installer(meta)
    else
        return true  -- installation not required
    end
end

function registerExtension(id, extension)
    extensions[id] = {
        globalKeys = extension.globalKeys or {},
        clientKeys = extension.clientKeys or {},
        signals = extension.signals or {},
        widgets = extension.widgets or {},
        init = extension.init or nil
    }
end

function dconf_schema_has_key(s, key)
    -- helper to check whether schema has key specified
    local keys = s:list_keys()
    for _, x in pairs(keys) do
        if x == key then
            return true
        end
    end
    return false
end

function registerInstallableExtension(id, meta)
    installable_extensions[id] = meta
end

function get_desktop_setting(schema, key, default)
    -- read setting from dconf registry and update local cache
    local s = dconfschemas[schema] or nil
    local v = default
    if s then
        if dconf_schema_has_key(s, key) then
            v = s:get_string(key) or default
        end
    end
    desktopsettings[schema][key] = v
    return v
end

function dconf_schema_connect(schema, signal, callback)
    local s = dconfschemas[schema] or nil
    if s then
        local sigt = s['on_'..signal]
        if sigt then
            return sigt:connect(callback)
        end
    end
end

function desktop_setup_screen_wallpaper(s)
    local wall = get_desktop_setting(
    "org.gnome.desktop.background", "picture-uri",
    beautiful.fallback_wallpaper)
    if wall then
        local mode = get_desktop_setting(
        "org.gnome.desktop.background", "picture-options", "zoom")
        if mode == "zoom" then
            gears.wallpaper.maximized(wall:gsub("^file://", ""), s)
        elseif mode == "wallpaper" then
            local c = get_desktop_setting(
            "org.gnome.desktop.background", "primary-color", "#333333")
            gears.wallpaper.set(c)
        end
    end
end

function initializeTheme()
    beautiful.init(THEMES_PATH .. "awmd/theme.lua")
end


local AWMD = {
    app_launcher = nil,
    conf = awmd_config,
    gsettings = gtk.Settings.get_default(),

    connect_signal = function(signal, callback)
        return awmd_object:connect_signal(signal, callback)
    end,
    lookupIcon = function(name, size)
        return icontheme.lookup_icon(name, size or 24, 0)
    end
}
AWMD.__index = AWMD


function AWMD:new (root, o)
    o = o or {}
    o.root = root
    o.globalkeys = {}
    o.clientkeys = {}
    return setmetatable(o, AWMD)
end


function AWMD.init(self)
    awful.util.modkey = self.conf.modkey

    -- enableExtension("alttab_window_switcher")
    enableExtension("awmd-rofi")
    enableExtension('awmd-defaults')


    loadGnomeDesktopSettings()
    updateAWMDConfig()
    initializeTheme()


    dconf_schema_connect(
    "org.gnome.desktop.background", "change-event",
    function()
        desktop_setup_screen_wallpaper()
    end)

    -- auto refresh intenal config

    dconf_schema_connect(
    'org.gnome.desktop.interface', 'change-event',
    function()
        updateAWMDConfig()
        initializeTheme()
        -- TODO: refresh/redraw wibox/widgets
    end)


    self.mykeyboardlayout = awful.widget.keyboardlayout()

    initializeEnabledExtensions(self)

    self:initOldRC()

    awful.screen.connect_for_each_screen(function(s)
        self:onScreenInit(s)
    end)

    -- saveSettings(self)
end

function AWMD.onScreenInit(self, s)
    require("awmd-widgets")
    desktop_setup_screen_wallpaper(s)
end

function AWMD.addGlobalKeys(self, t)
    self.globalkeys = gears.table.join(self.globalkeys, t)
end

function AWMD.getTags (self) 
    return self.conf.tags
end

function AWMD.addClientKeys(self, t)
    self.clientkeys = gears.table.join(self.clientkeys, t)
end

function AWMD.desktop_setting(schema, key, default)
    return get_desktop_setting(schema, key, default)
end

function AWMD.initOldRC(self)

    -- {{{ Mouse bindings
    local root = self.root
    local modkey = self.conf.modkey

    root.buttons(gears.table.join(
    awful.button({ }, 3, function () awmd_menu.get_desktop_menu():toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
    ))
    -- }}}


    -- {{{ Key bindings

    globalkeys = self.globalkeys
    clientkeys = self.clientkeys

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

end


function enableExtension(extension_id)
    local ext = extensions[extension_id]

    if not ext then
        -- search in installable extensions / autoinstall
        local meta = installable_extensions[extension_id]

        if not meta then
            meta = require(extension_id)
        end
            -- try to install
        if installExtension(meta) then
            -- load and register if available
            ext = loadExtension(meta)
            if ext then
                registerExtension(extension_id, ext)
            end
        end
    end

    if ext then
        table.insert(active_extensions, ext)
    end
end


function initializeEnabledExtensions(awmd)
    for _, x in pairs(active_extensions) do
        if x.init then
            x.init(awmd, {})
        end
    end
end


if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
        title = "Oops, an error happened!",
        text = tostring(err) })
        in_error = false
    end)
end
-- }}}

function runAWMD(root, conf)
    local app = AWMD:new(root, conf)
    app:init()
end


-- awmd initialization

return {
    run = runAWMD,
    -- BC
    conf = AWMD.conf,
    connect_signal = AWMD.connect_signal,
    init = runAWMD,
}
