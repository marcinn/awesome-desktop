local gears = require("gears")
local awful = require("awful")

local globalkeys = {}
local clientkeys = {}
local extensions = {}
local installable_extensions = {}
local active_extensions = {}
local tags = {"1", "2", "3", "4"}
local awmd = {}

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

local awmd = {
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
    initializeEnabledExtensions = function()
        for _, x in pairs(active_extensions) do
            if x.init then
                x.init()
            end
        end
    end,
    onScreenInit = function()
        require("awmd-widgets")
    end
}

local defaults = require("awmd-defaults")
registerExtension('__awmd_defaults__', defaults)
awmd.enableExtension('__awmd_defaults__')

local known_extensions = require("awmd-extensions")
for id, x in pairs(known_extensions) do
    awmd.registerInstallableExtension(id, x)
end

return awmd
