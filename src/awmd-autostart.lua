local spawn = require("awful.spawn")

-- polkit / auth
os.execute("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")

-- compositor
os.execute("picom --backend glx --paint-on-overlay --vsync &")

os.execute("killall -9 pamac-tray")
os.execute("pamac-tray &")

os.execute("killall -9 xflux")
os.execute("xflux -l 50.266667 -g 19.0166667")

os.execute("killall -9 pa-applet")
os.execute("pa-applet --disable-key-grabbing &")

-- locking screen

os.execute("killall -9 xidlehook")
os.execute("xidlehook --not-when-fullscreen --not-when-audio --timer 40 '~/bin/backlightctl dim' '~/bin/backlightctl undim' --timer 60 '~/bin/backlightctl undim && i3lock-fancy -b=0x8' '' &")

-- dual head setup
os.execute("~/bin/dualhead")

-- other

spawn.with_shell("/usr/lib/gnome-settings-daemon/gsd-xsettings")
spawn.with_shell("sleep 3; nm-applet")
