-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Widgets library
require("vicious")

-- Load Debian menu entries
require("debian.menu")

-- Expose like
require("revelation")

-- Sound Control
function volume (mode, channel)
    local volumedifference = "5dB"
    local cardid  = 0
    if mode == "get" then
        local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
        local status = fd:read("*all")
        fd:close()
        local volume = string.match(status, "(%d?%d?%d)%%")
        volume = string.format("% 3d", volume)
        return volume
    elseif mode == "up" then
        io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " " .. volumedifference .. "+"):read("*all")
        return volume("get", channel)
    elseif mode == "down" then
        io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " " .. volumedifference .. "-"):read("*all")
        return volume("get", channel)
    else
        return volume("get", channel)
    end
end

-- MPD Control
function mediaplayer (action)
    local mpd_status
    local mpd_text

    if action == "stop" then
        io.popen("mpc stop")
        mpd_status = "stop"
        mpd_text = "Stopped"
    end
    
    local fd
    if action == "toggle" then
        fd = io.popen("mpc toggle")
    elseif action == "next" then
        fd = io.popen("mpc next")
    elseif action == "prev" then
        fd = io.popen("mpc prev")
    end

    if (not (fd == nil)) then
        song_name = fd:read("*line")
        status_line = fd:read("*line")
        fd:close()
        _, _, mpd_status, duration = string.find(status_line, "%[(%a+)%].*%d*:%d*/(%d*:%d*).*")
        mpd_text = song_name .. " (" .. duration .. ")"
    end
    
    mpd_status = mpd_status:gsub("%a", string.upper, 1)
    
    if (mpd_status == "Playing") then
        mpd_status = "<span color='#33CC00'>" .. mpd_status .. "</span>"
    else
        mpd_status = "<span color='#FF0000'>" .. mpd_status .. "</span>"
    end

    os.execute("rm -f /tmp/FRONT_COVER*")
    os.execute('eyeD3 -i /tmp "Music/`mpc -f "%file%" | sed 1q`" &> /dev/null')

    naughty.notify({ title = mpd_status, text = mpd_text, icon = "/tmp/FRONT_COVER.jpeg", icon_size = 100, timeout = 2 })
end

-- Backlight control
function backlight (action)
    if action == "inc" then
        io.popen("xbacklight -inc 50")
    elseif action == "dec" then
        io.popen("xbacklight -dec 50")
    end
end

-- Search google through surfraw
function search_google (search_term)
    io.popen("sr google " .. search_term)
end

function search_wikipedia (search_term)
    io.popen("sr wikipedia " .. search_term)
end

-- Lock mechanism
function screen_lock ( )
    local auth = "-auth pam"
--    local back = "-bg image:scale,file=/home/valdor/Pictures/Wallpapers/41f151a72f549c1a2eb60ae7f4f35f42.png"
    local back = "-bg image:scale,file=/home/valdor/Pictures/Wallpapers/wallpaper-1099241.jpg"
    local curs = ""
    io.popen("alock" .. " " .. auth .. " " .. back .. " " .. curs)
end

-- Sleep, shutdown and reboot actions 
function power_function (action)
    naughty.notify({ title = "Menu", text = action, timeout = 2 })
    if (action == "Suspend") then
        screen_lock()
        action = action .. " int32:0"
    end

    io.popen('dbus-send --system --print-reply --dest="org.freedesktop.Hal" /org/freedesktop/Hal/devices/computer org.freedesktop.Hal.Device.SystemPowerManagement.' .. action)
end

-- Information about active client
function client_function ( )
    local pid = awful.client.getmaster().pid

    local fd = io.popen("ps -o pcpu " .. pid)
    fd:read("*line")
    local cpu_percent = fd:read("*line")
    fd:close()

    local fd2 = io.popen("cat /proc/" .. pid .. "/status | grep VmRSS | awk '{print $2}' | perl -pe 's/.*?(\\\d+).*/$1/ ; $_ = $1/1024;'")
    local memory = fd2:read("*line")
    fd2:close()

    cpu_percent = cpu_percent .. "%"
    memory = math.floor( (memory * 100) + 0.5) / (100) .. "MB"

    naughty.notify({ title = "Client: " .. awful.client.getmaster().name, text = "PID: " .. pid .. "\nCPU: " .. cpu_percent .. "\nMemory : " .. memory, timeout=10})
end

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/valdor/.config/awesome/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }, s, layouts[6])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}


mypowermenu = {
    { "Suspend",  power_function },
    { "Reboot",  power_function },
    { "Shutdown",  power_function },
}



mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal },
                                    { "power", mypowermenu}
                                    }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

mysystray = widget({ type = "systray" })

-- Separator
separator = widget({ type = "textbox" })
separator.text = " | "

-- Vicious widgets
-- MPD widget
mpdwidget = widget({ type = "textbox" })
vicious.register(mpdwidget, vicious.widgets.mpd,
    function (widget, args)
        if args["{state}"] == "Stop" then 
            return "(Stopped)"
        else 
            return args["{Artist}"]..' - '.. args["{Title}"]
        end
    end, 5)

-- Battery widget
batwidget = widget({ type = "textbox" })
vicious.register(batwidget, vicious.widgets.bat, "$1 $2% ($3)", 10, "BAT1")

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                             return awful.widget.tasklist.label.currenttags(c, s)
                                         end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        separator,
        mytextclock,
        separator,
        mpdwidget,
        separator,
        batwidget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift"   }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Personal bindings
    awful.key({ modkey }, "g",
              function ()
                  awful.prompt.run({ prompt = "Search Google: " },
                  mypromptbox[mouse.screen].widget,
                  search_google, nil, awful.util.getdir("cache") .. "/history_search")
              end),
    awful.key({ modkey }, "w",
              function ()
                  awful.prompt.run({ prompt = "Search Wikipedia: " },
                  mypromptbox[mouse.screen].widget,
                  search_wikipedia, nil, awful.util.getdir("cache") .. "/history_search")
              end),
    awful.key({modkey   }, "e",  revelation.revelation),
    awful.key({modkey   }, "c",
        function()
            awful.prompt.run({ prompt = "Calculate: " }, mypromptbox[mouse.screen].widget,
            function (expr)
                naughty.notify({ title = "Calculator", text = expr .. ' = ' .. awful.util.eval("return (" .. expr .. ")"), timeout = 15})
            end)
        end),
    -- Volume Controls
    awful.key({         }, "XF86AudioRaiseVolume", 
        function()
            local result = volume("up", "Master")
            naughty.notify({ title = "Master raised", text = "Set to " .. result, timeout = 2 })
        end),
    awful.key({         }, "XF86AudioLowerVolume",
        function()
            local result = volume("down", "Master")
            naughty.notify({ title = "Master lowered", text = "Set to " .. result, timeout = 2 })
        end),
    awful.key({"Shift"  }, "XF86AudioRaiseVolume", 
        function()
            local result = volume("up", "Speaker")
            naughty.notify({ title = "Speaker raised", text = "Set to " .. result, timeout = 2 })
        end),
    awful.key({"Shift"  }, "XF86AudioLowerVolume",
        function()
            local result = volume("down", "Speaker")
            naughty.notify({ title = "Speaker lowered", text = "Set to " .. result, timeout = 2 })
        end),
    awful.key({"Control" }, "XF86AudioRaiseVolume", 
        function()
            local result = volume("up", "Headphone")
            naughty.notify({ title = "Headphone raised", text = "Set to " .. result, timeout = 2 })
        end),
    awful.key({"Control"  }, "XF86AudioLowerVolume",
        function()
            local result = volume("down", "Headphone")
            naughty.notify({ title = "Headphone lowered", text = "Set to " .. result, timeout = 2 })
        end),
    -- MPD Controls
    awful.key({         }, "XF86AudioPlay",
        function()
            mediaplayer("toggle")
            vicious.force({mpdwidget})
        end),
    awful.key({         }, "XF86AudioStop",
        function()
            mediaplayer("stop")
            vicious.force({mpdwidget})
        end),
    awful.key({         }, "XF86AudioNext",
        function()
            mediaplayer("next")
            vicious.force({mpdwidget})
        end),
    awful.key({         }, "XF86AudioPrev",
        function()
            mediaplayer("prev")
            vicious.force({mpdwidget})
        end),
    -- CRT/LCD key
    awful.key({         }, "#235",
        function()
            io.popen("roll_xrandr")
            local fd = io.popen("cat /tmp/rollxrandr-valdor")
            local screen = fd:read("*all")
            fd:close()
            naughty.notify({ title = "Displays", text = screen, timeout = 10})
        end),
    awful.key({         }, "Print",
        function()
            io.popen("scrot")
            os.execute("sleep 1")
            naughty.notify({ title = "Screenshot taken", timeout = 2 })
        end),
    awful.key({"Control"  }, "Print",
        function()
            io.popen("scrot -u")
            os.execute("sleep 1")
            naughty.notify({ title = "Window screenshot taken", timeout = 2 })
        end),
    awful.key({"Shift"  }, "Print",
        function()
            io.popen("scrot -s")
            os.execute("sleep 1")
            naughty.notify({ title = "Window screenshot taken", timeout = 2 })
        end),
    awful.key({modkey   }, "F1", 
        function()
            screen_lock()
        end),
    awful.key({         }, "XF86MonBrightnessUp",
        function()
            backlight("inc")
        end),
    awful.key({         }, "XF86MonBrightnessDown",
        function()
            backlight("dec")
        end),
    -- Client information
    awful.key({ modkey  }, "i", 
        function()
            client_function()
        end)

)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end)
)

-- Compute the maximum number of digit we need, limited to 10
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(10, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 0 to 9.
for i = 0, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     maximized_vertical   = false,
                     maximized_horizontal = false,
                     size_hints_honor = false,
                     buttons = clientbuttons } },
    { rule = { class = "Conky" },
      properties = { floating = true } },
    { rule = { instance = "Navigator" },
      properties = { tag = tags[1][1] } },
    { rule = { instance = "Mail" },
      properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
-- client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{ Some personal stuff
client.add_signal("focus", function(c)
                              c.border_color = beautiful.border_focus
                              c.opacity = 1
                           end)
client.add_signal("unfocus", function(c)
                                c.border_color = beautiful.border_normal
                                c.opacity = 0.7
                             end)

