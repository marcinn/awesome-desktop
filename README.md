# awesome-desktop
A simple desktop environment based on AwesomeWM framework and Gnome
stack

# Installation

**Only manual installation. Makefile is in progress**

Clone the repository somewhere:

```
git clone https://github.com/marcinn/awesome-desktop.git
```

Make required directories:

```
mkdir ~/.config/awesome
mkdir ~/.config/awesome/awmd-extensions
```

Setup symlinks:

```
cd ~/.config/awesome
ln -s /path/to/awesome-desktop/src awmd
ln -s /path/to/awesome-desktop/src/rc.lua
ln -s /path/to/awesome-desktop/themes/
ln -s /path/to/awesome-desktop/bin/
```

Create required extensions:
```
cd ~/.config/awesome/awmd-extensions
git clone https://github.com/pltanton/net_widgets.git
git clone https://github.com/streetturtle/awesome-wm-widgets.git
```

Create empty autostart file for your programs:

```
touch ~/.config/awesome/autostart.lua
```

Install required dependencies.
Restart AwesomeWM & pray.

## Goals

- **configuration and extensibility without mmodyfiing LUA code**
- **sane defaults, preconfigured DE for advanced but regular user**
- freedesktop.org: autostart
- freedesktop.org: theming, icons
- multihead support
- plugins/extensions layer
- rule based widgets activation
- GUI: displays configuration
- GUI: panels and widgets management
- GUI: settings manager
- GUI: plugins/extensions management
- Widgets: native widget for NetworkManager
- Widgets: notifications area
- Widgets: laptop-specific widgets (battery, brightness)
- Widgets: cpu throttling widget (similar to https://extensions.gnome.org/extension/945/cpu-power-manager/)

## Motivations

- AwesomeWM is a more framework than complete desktop environment
- most of configs/themes available on the web, are built from scratch, incompatible, and have poor quality
- most of widgets available on the web have poor quality
- **there is no complete DE built top of AwesomeWM** - everyone **must** create own enviroment based on `rc.lua` variations
- Gnome3 delivers a good stack and utilities

## Dependencies

- `awesome-desktop` (from Arch User Repository or something similar):
  session and configuration files which runs AwesomeWM as a Gnome
  session
- `osd_cat` (xosd): display OSD
- `polkit-gnome-authentication-agent-1` (polkit-gnome): authentication
  agent
- `picom`: compositor
- `nmcli` (NetworkManager): manage and retrieve info about networking
- `xbacklight` (acpilight, xorg-xbacklight): control laptop backlight
- `python` (Python 3): for utilities
- `python-gobject`
- `gnome-screenshot` (Gnome Screenshot): take screenshots
- `convert` (ImageMagick): for lockscreen blur
- `notify-send` (libnotify): send desktop notifications
- `pulseaudio-ctl` (PulseAUdio, pulseaudio-ctl): manage audio
- `xdg-user-dir` (xdg-user-dirs): read user dirs
- `lain`: widgets and utilities for AwesomeWM
- `lgi` (GLib for LUA): access GObject libraries
- `Droid Sans Mono` font: used in default theme
- `xidlehook` and `i3lock-fancy`: locking screen
- `pa-applet`: volume control applet (pulseaudio)
- `nm-applet`: tray icon for network manager
- `xflux`: night mode
- `rofi`: powerful app launcher / window switcher
- Gnome stack


### Dependencies to be moved to extensions
- `net_widgets` (https://github.com/pltanton/net_widgets.git)
- `vicious`
- `wibox`
- `touchpad_widget`
- `awesome-wm-widgets`


### Optional dependencies

- `awesome-switcher`

### Optional utilities

- `synclient` and `syndaemon`: handling touchpad options
- `pamac-tray`: display notification about Manjaro/Arch updates in tray

Setup multihead:
- `xrandr`: manual setup
- autorandr (https://github.com/phillipberndt/autorandr)
- arandr

