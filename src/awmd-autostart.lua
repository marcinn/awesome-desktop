local spawn = require("awful.spawn")
local awmd = require("awmd")

-- polkit / auth
os.execute("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")

-- compositor
os.execute("picom --backend glx --paint-on-overlay --vsync -I 1 -O 1 -D 0 &")

os.execute("killall -9 pamac-tray")
os.execute("pamac-tray &")

os.execute("killall -9 xflux")
os.execute("xflux -l 50.266667 -g 19.0166667")

os.execute("killall -9 pa-applet")
os.execute("pa-applet --disable-key-grabbing &")

-- locking screen

os.execute("killall -9 xidlehook")
os.execute("xidlehook --not-when-fullscreen --not-when-audio --timer 40 '" .. awmd.conf.commands.backlightctl .. " dim' '" .. awmd.conf.commands.backlightctl .. " undim' --timer 60 '" .. awmd.conf.commands.backlightctl .. " undim && awmd-lock' '' &")

-- dual head setup
os.execute(awmd.conf.commands.displayctl .. " setup")

-- other

spawn.with_shell("/usr/lib/gnome-settings-daemon/gsd-xsettings")
spawn.with_shell("sleep 3; nm-applet")
