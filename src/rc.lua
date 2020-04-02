local gears = require("gears")
local confdir = gears.filesystem.get_configuration_dir()
package.path = confdir .. "awmd/?.lua;" .. confdir .. "awmd-extensions/?/init.lua;" .. package.path 

--

local awmd = require("awmd")
awmd.init(root)

--

require("awmd-autostart")
require("autostart")
