# awesome-desktop
A simple desktop environment based on AwesomeWM framework and Gnome
stack

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

- `osd_cat`
- `nmcli` (NetworkManager)
- `xbacklight`
- `python` (Python 3)
- `python-gobject`
- `gnome-screenshot` (Gnome Screenshot)
- `convert` (ImageMagick)
- `notify-send` (libnotify)
- `pulseaudio-ctl` (PulseAUdio, pulseaudio-ctl)
- `xdg-user-dir` (xdg-user-dirs)
- Droid Sans Mono font
- Gnome stack


## Optional dependencies

- rofi

## Utilities

- autorandr (https://github.com/phillipberndt/autorandr)
- arandr
