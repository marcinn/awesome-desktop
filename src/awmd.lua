require("awful.autofocus")

local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local lgi = require("lgi")
local gtk = lgi.require("Gtk")
local gio = lgi.require("Gio")
local gfs = require("gears.filesystem")

local THEMES_PATH = gfs.get_configuration_dir() .. 'themes/'

local globalkeys = {}
local clientkeys = {}
local extensions = {}
local installable_extensions = {}
local active_extensions = {}
local tags = {"1", "2", "3", "4"}
local desktopsettings = {}
local dconfschemas = {}
local awmd_config = {}
local awmd_object = gears.object { enable_properties = false, class = 'AWMD' }

local _desktopsettingschemas = {
    "org.gnome.",
    "org.awesomewm.",
}

local icontheme = gtk.IconTheme.get_default()

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
        return meta.factory(module)
    else
        return nil
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

local awmd = {
    conf = awmd_config,
    gsettings = gtk.Settings.get_default(),
    desktop_setting = get_desktop_setting,
    getGlobalKeys = function()
        return gears.table.join(globalkeys, getExtensionsGlobalkeys())
    end,
    getClientKeys = function()
        return clientkeys
    end,
    addGlobalKeys = function(table)
        globalkeys = gears.table.join(globalkeys, table)
    end,
    addClientKeys = function(table)
        clientkeys = gears.table.join(clientkeys, table)
    end,
    getTags = function()
        return tags
    end,
    registerExtension = registerExtension,
    loadExtension = loadExtension,
    registerInstallableExtension = function(id, meta)
        installable_extensions[id] = meta
    end,
    enableExtension = function(extension_id)
        local ext = extensions[extension_id]

        if not ext then
            -- search in installable extensions / autoinstall
            local meta = installable_extensions[extension_id]
            if meta then
                -- try to install
                if installExtension(meta) then
                    -- load and register if available
                    ext = loadExtension(meta)
                    if ext then
                        registerExtension(extension_id, ext)
                    end
                end
            end
        end

        if ext then
            table.insert(active_extensions, ext)
        end
    end,
    initializeTheme = function()
        beautiful.init(THEMES_PATH .. "awmd/theme.lua")
    end,
    lookupIcon = function(name, size)
        return icontheme.lookup_icon(name, size or 24, 0)
    end,
    initializeEnabledExtensions = function()
        for _, x in pairs(active_extensions) do
            if x.init then
                x.init()
            end
        end
    end,
    onScreenInit = function(s)
        require("awmd-widgets")
        desktop_setup_screen_wallpaper(s)
    end,
    connect_signal = function(signal, callback)
        return awmd_object:connect_signal(signal, callback)
    end
}

loadGnomeDesktopSettings()
updateAWMDConfig()


-- auto refresh desktop background 

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
        beautiful.init(THEMES_PATH .. "marcin/theme.lua")
        -- TODO: refresh/redraw wibox/widgets
    end)

-- load defaults


local defaults = require("awmd-defaults")
registerExtension('__awmd_defaults__', defaults)
awmd.enableExtension('__awmd_defaults__')

local known_extensions = require("awmd-extensions")
for id, x in pairs(known_extensions) do
    awmd.registerInstallableExtension(id, x)
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
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

return awmd
