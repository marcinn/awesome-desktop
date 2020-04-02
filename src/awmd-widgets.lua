local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")
local lain = require("lain")
local dpi = xresources.apply_dpi
local net_widgets = require("net_widgets")
local vicious = require("vicious")
local watch = require("awful.widget.watch")
local switcher = require("awesome-switcher")
local PATH_TO_ICONS = "/usr/share/icons/Arc/status/symbolic/"
local awmd_menu = require("awmd-menu")
local awmd = require("awmd")

local glib = require("lgi").GLib
local DateTime = glib.DateTime
local TimeZone = glib.TimeZone

local sprtr = lain.util.separators.arrow_left(beautiful.bg_normal, "#343434")

local touchpad_widget = require("touchpad-widget")
local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
-- local weather_widget = require("awesome-wm-widgets.weather-widget.weather")
local brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")
local ram_widget = require("awesome-wm-widgets.ram-widget.ram-widget")
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
local cpufreq_widget = wibox.widget.textbox()
vicious.register(cpufreq_widget, vicious.widgets.cpufreq, function(widget, data) 
        return string.format("%.1f GHz", data[2])
    end, 7, "cpu0")
local touchpad = touchpad_widget:new({vendor="synaptic"})
local wireless = net_widgets.wireless({
    interface="wlp2s0",
    popup_signal = true,
    onclick = "gnome-control-center network",
})
-- local freedesktop = require("freedesktop")

local month_calendar = awful.widget.calendar_popup.month({})
function month_calendar.call_calendar(self, offset, position, screen)
    local screen = awful.screen.focused()
	awful.widget.calendar_popup.call_calendar(self, offset, position, screen)
end
mytextclock = wibox.widget.textclock(awmd.conf.clock_format)
month_calendar:attach(mytextclock, "tr")
awmd.connect_signal('config::changed',  function()
    -- unsupported in 4.2 yet
    -- mytextclock:set_format(awmd.conf.clock_format)
    -- mytextclock:emit_signal('timeout')
    --
    -- maybe ask for awesome.restart() ?
end)

local bt_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
        resize = false
    },
    layout = wibox.container.margin(_, 0, 0, 3)
}
local systray_widget = wibox.widget.systray()

watch("bluetooth", 11,
    function(widget, stdout, stderr, exitreason, exitcode)
    if stdout:find( "tooth = on") then
        widget.icon:set_image(PATH_TO_ICONS .. "bluetooth-active-symbolic.svg")
        widget._btenabled = true
    else
        widget.icon:set_image(PATH_TO_ICONS .. "bluetooth-disabled-symbolic.svg")
        widget._btenabled = false
    end
end, bt_widget)


beautiful.menu = awmd_menu.get_desktop_menu()

local mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = beautiful.menu })




local function widget(w)
    return wibox.container.margin(w, dpi(6), dpi(6), dpi(2))
end

local function widgetsection(widgets, color)
    local color = color or beautiful.widget_transparent
    local result = {
    --    lain.util.separators.arrow_left(beautiful.bg_normal, color),
    }   
    for _, w in pairs(widgets) do
        table.insert(result, wibox.container.background(w, color))
    end
    --table.insert(
    --    result,
    --    lain.util.separators.arrow_right(color, beautiful.bg_normal))
    result["layout"] = wibox.layout.fixed.horizontal
    return wibox.container.margin(wibox.widget { result, layout = wibox.layout.fixed.horizontal }, dpi(12), dpi(12), 0, 0, beautiful.widget_transparent)
end

-- notifications history

local notifications_history = {}
local notifications_history_unread_count = 0
local notifications_history_menu = nil
local notifications_history_widget_icon = wibox.widget.imagebox(
    PATH_TO_ICONS .. "notification-symbolic.svg")
local notifications_history_widget_unread = wibox.widget.textbox("0")

local notifications_history_widget = wibox.widget {
    wibox.container.margin(notifications_history_widget_icon, dpi(2), dpi(2), dpi(4), dpi(2)),
    notifications_history_widget_unread,
    layout = wibox.layout.fixed.horizontal
}

local function update_notifcations_unread_count(cnt)
    cnt = cnt or 0
    notifications_history_unread_count = cnt
    if cnt > 0 then
        notifications_history_widget_icon.image = PATH_TO_ICONS .. "notification-new-symbolic.svg"
    else
        notifications_history_widget_icon.image = PATH_TO_ICONS .. "notification-symbolic.svg"
    end
    notifications_history_widget_unread.text = cnt
end

naughty.config.notify_callback = function(args)
    if args.freedesktop_hints and not args._stored_in_history then
        args._stored_in_history = true
        table.insert(notifications_history, 1, {
            time = DateTime.new_now(TimeZone.new_local()),
            args = args
        })
        if #notifications_history > 10 then
            table.remove(notifications_history, #notifications_history)
        end
        update_notifcations_unread_count(notifications_history_unread_count+1)
    end
    return args
end

notifications_history_widget:connect_signal(
    "button::press", function(x, y, btn, mods, fwr)
        if notifications_history_menu then
            notifications_history_menu:hide()
            notifications_history_menu = nil
            return
        end

        local items = {}
        local m = awful.menu()
        notifications_history_menu = m

        local function showdetail(x)
            local msg = {}
            m:hide()
            notifications_history_menu = nil

            for k, v in pairs(x) do
                msg[k] = v
            end
            msg.timeout = 0
            naughty.notify(msg)
            -- if x.run then
            --    x.run()
            --else
            --    naughty.notify(x)
            --end
        end

        for i, item in pairs(notifications_history) do
            local t = item.time
            local x = item.args
            local prefix = t:format("%a %b %d, %H:%M") .. ": "

            if x.appname then prefix = "(" .. x.appname .. ") " .. prefix end
            if x.title then prefix = prefix .. " [" .. x.title .. "] " end
            m:add({prefix .. x.text, function() showdetail(x) end, x.icon})
        end
        m:show()
        update_notifcations_unread_count(0)
    end)


-- end notification history


local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ awmd.conf.modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ awmd.conf.modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(
        gears.table.map(function(x) return ' '..x..' ' end, awmd.conf.tags),
        s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, opacity=1.0, bg = beautiful.bg_normal })

    -- Add widgets to the wibox
    s.mywibox:setup {
        {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            systray_widget,
            widgetsection({
                widget(touchpad.widget),
            }),
            widgetsection({
                widget(cpu_widget),
                widget(cpufreq_widget),
                widget(ram_widget),
            }),
            widgetsection({
                widget(brightness_widget),
                widget(battery_widget),
                widget(wireless),
                widget(bt_widget),
				widget(mynetworklauncher),
            }),
            widgetsection({
                widget(notifications_history_widget),
            }),
            mytextclock,
            wibox.container.place(wibox.container.margin(s.mylayoutbox, dpi(6), dpi(6), dpi(6), dpi(6))),
        },
    },
        widget = wibox.container.margin,
        color = '#000000',
        bottom = dpi(2),
    }
end)
