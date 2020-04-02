local gears = require('gears')
local awful = require('awful')


local default_config = {
    rofi = {
        ["theme"] = "purple",
        ["combi-modi"] = "window,drun,ssh",
        ["show-icons"] = "true",
        ["show"] = "combi"
    }
}


function initializeExtension(awmd, config)
    local config = gears.table.join(default_config, config)
    local bin = config.rofi_bin or 'rofi'
    local args = {bin}

    for k,v in pairs(config.rofi or {}) do
        table.insert(args, '-' .. k)
        table.insert(args, v)
    end

    local cmd = table.concat(args, ' ')

    awmd.app_launcher = function() awful.spawn.with_shell(cmd) end
end


local ext = {
    init = initializeExtension
}

return ext
