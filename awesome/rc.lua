-- Standard awesome library
local gears      =   require("gears")
local awful      =   require("awful")
awful.rules      =   require("awful.rules")
require("awful.autofocus")

-- Pulseaudio widget
local APW = require("apw/widget")

-- Notification library
local naughty    =   require("naughty")
local menubar    =   require("menubar")

-- Widgets library
local wibox      =   require("wibox")

-- Load Debian menu entries
local debianMenu =   require("debian.menu")

-- Load Lain libraries
local lain = require("lain")

-- Help
local keydoc = require("keydoc")

-- Theme handling library
local beautiful  =   require("beautiful")


-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

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
        _, _, mpd_status, playlist_pos, duration = string.find(status_line, "%[(%a+)%]%s+#(%d*.%d*)%s+%d*:%d*/(%d*:%d*).*")
        mpd_text = song_name .. " (" .. duration .. ")" .. " [" .. playlist_pos .. "]"
        mpd_text = string.gsub(mpd_text, "&", "&amp;")
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
        awful.util.spawn_with_shell("xbacklight -inc 20")
    elseif action == "dec" then
        awful.util.spawn_with_shell("xbacklight -dec 20")
    end
end

-- Lock mechanism
function screen_lock ( )
    local lock_folder=os.getenv("HOME") .. "/Divers/Lockscreens/"
    local auth = "-auth pam"
    local locks_iterator = io.popen('ls "' .. lock_folder .. '"'):lines()
    local locks = {}
    for v in locks_iterator do
        locks[#locks + 1] = v
    end
    local lock_number = math.random(1,#locks)
    local back = "-bg image:scale,file='" .. lock_folder .. locks[lock_number] .. "'"
    local curs = ""
    awful.util.spawn_with_shell(os.getenv("HOME") .. "/.local/bin/alock" .. " " .. auth .. " " .. back .. " " .. curs)
end

-- Sleep, shutdown and reboot actions 
function power_function (action, menu)
    naughty.notify({ title = "Menu", text = menu, timeout = 2 })
    if (action == "Suspend") then
        screen_lock()
        io.popen('sudo s2ram --force')
    elseif (action == "Hibernate") then
        screen_lock()
        io.popen('sudo s2disk')
    else
         naughty.notify({ title = "Unknown error", text = "Unknown action " .. action .. "."})
    end
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
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/valdor/theme.lua")

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
    awful.layout.suit.max,
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

-- {{{ Wallpaper
local wp_timeout = 60
local wp_path = os.getenv("HOME") .. "/Divers/Wallpapers/"
local wp_init = function ()
    local walls_iterator = io.popen('ls "' .. wp_path .. '"'):lines()
    walls = {}
    for v in walls_iterator do
        walls[#walls + 1] = v
    end 
end

local wp_load = function ()
    for s = 1, screen.count() do
        local wall_number = math.random(1,#walls)
        local back =  wp_path .. walls[wall_number]
        gears.wallpaper.maximized(back, s, false)
    end

    wp_timer:stop()
    wp_timer.timeout = wp_timeout
    wp_timer:start()
end

wp_timer = timer { timeout = wp_timeout }
wp_timer:connect_signal("timeout", wp_load)

wp_init()
wp_load()

math.randomseed( os.time() )
for i = 1, 1000 do tmp=math.random(0,1000) end
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
    { "Suspend",  function() power_function("Suspend") end },
}


mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debianMenu.Debian_menu.Debian },
                                    { "open terminal", terminal },
                                    { "power", mypowermenu}
                                    }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()
lain.widgets.calendar:attach(mytextclock, { cal = "/usr/bin/cal -h" })

-- Separator
spr = wibox.widget.textbox('|')

batwidget0 = lain.widgets.bat({
    battery = "BAT0",
    settings = function()
        local arrow = "→"
        if bat_now.status == "Charging" then
            arrow = "↑"
        end
        if bat_now.status == "Discharging" then
            arrow = "↓"
        end
        widget:set_text("0: " .. arrow .. " " .. bat_now.perc .. "% (" .. bat_now.time .. ")")
    end
})

batwidget1 = lain.widgets.bat({
    battery = "BAT1",
    notify = "off",
    settings = function()
        local arrow = "→"
        if bat_now.status == "Charging" then
            arrow = "↑"
        end
        if bat_now.status == "Discharging" then
            arrow = "↓"
        end
        widget:set_text("1: " .. arrow .. " " .. bat_now.perc .. "% (" .. bat_now.time .. ")")
    end
})

-- Coretemp
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widgets.temp({
    settings = function()
        widget:set_text(" " .. coretemp_now .. "°C ")
    end
}, "#313131")


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
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(APW)
    right_layout:add(spr)
    right_layout:add(tempicon)
    right_layout:add(tempwidget)
    right_layout:add(spr)
    right_layout:add(mytextclock)
    right_layout:add(spr)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
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
    keydoc.group("Focus"),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev ,  "Switch to next workspace" ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext ,  "Switch to previous workspace" ),

    awful.key({ modkey,           }, "j", function () awful.client.focus.byidx( 1) if client.focus then client.focus:raise() end end, "Focus next window"),
    awful.key({ modkey,           }, "k", function () if client.focus then client.focus:raise() end end, "Focus previous window"),
    awful.key({ modkey, "Shift"   }, "w", function () mymainmenu:show({keygrabber=true}) end, "Open Awesome Menu"),

    -- Layout manipulation
    keydoc.group("Layout manipulation"),
    awful.key({ modkey, "Shift"   }, "j",     function () awful.client.swap.byidx(  1)    end, "Swap with first window" ),
    awful.key({ modkey, "Shift"   }, "k",     function () awful.client.swap.byidx( -1)    end, "Swap with last window" ),
    awful.key({ modkey, "Control" }, "j",     function () awful.screen.focus_relative( 1) end, "Swap with next window" ),
    awful.key({ modkey, "Control" }, "k",     function () awful.screen.focus_relative(-1) end, "Swap with previous window" ),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end, "Increase main column width/height"),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end, "Decrease main column width/height"),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end, "?"),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end, "?"),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end, "?"),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end, "?"),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end, "Switch to next layout"),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end, "Switch to previous layout"),

    -- Standard program
    keydoc.group("Standard Utilities"),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end, "Terminal"),
    awful.key({ modkey, "Control" }, "r",      awesome.restart , "Restart Awesome"),
    awful.key({ modkey, "Shift"   }, "q",      awesome.quit, "Quit Awesome"),

    awful.key({ modkey,           }, "r",      function () mypromptbox[mouse.screen]:run() end, "Run prompt"),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end, "Lua prompt"),

    -- Personal bindings
    awful.key({ modkey,           }, "w",
        function()
            wp_init()
            wp_load()
        end, "Refresh wallpaper"),
    awful.key({modkey   }, "c",
        function()
            awful.prompt.run({ prompt = "Compute: " }, mypromptbox[mouse.screen].widget,
            function (expr)
                naughty.notify({ title = "Calculator", text = expr .. ' = ' .. awful.util.eval("return (" .. expr .. ")"), timeout = 15})
            end)
        end, "Calculator"),
    -- Volume Controls
    awful.key({         }, "XF86AudioRaiseVolume",  APW.Up),
    awful.key({         }, "XF86AudioLowerVolume",  APW.Down),
    awful.key({         }, "XF86AudioMute",         APW.ToggleMute),
    -- MPD Controls
    awful.key({         }, "XF86AudioPlay",
        function()
            mediaplayer("toggle")
        end),
    awful.key({         }, "XF86AudioStop",
        function()
            mediaplayer("stop")
        end),
    awful.key({         }, "XF86AudioNext",
        function()
            mediaplayer("next")
        end),
    awful.key({         }, "XF86AudioPrev",
        function()
            mediaplayer("prev")
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
        end, "Screenshot"),
    awful.key({"Control"  }, "Print",
        function()
            io.popen("scrot -u")
            os.execute("sleep 1")
            naughty.notify({ title = "Window screenshot taken", timeout = 2 })
        end, "Screenshot Window only"),
    awful.key({"Shift"  }, "Print",
        function()
            io.popen("scrot -s")
            os.execute("sleep 1")
            naughty.notify({ title = "Window screenshot taken", timeout = 2 })
        end, "Screenshot Selection"),
    awful.key({modkey   }, "F12",                   function() screen_lock() end,     "Lock Screen"),
    awful.key({ modkey  }, "F1",                    keydoc.display,                   "Display help"), 
    awful.key({         }, "XF86MonBrightnessUp",   function() backlight("inc") end,  "Increase brightness"),
    awful.key({         }, "XF86MonBrightnessDown", function() backlight("dec") end , "Decrease brightness"),
    awful.key({ modkey  }, "i",                     function() client_function() end, "Client information")

)

clientkeys = awful.util.table.join(
    keydoc.group("Client manipulation"),    
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end, "Switch fullscreen"),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end, "Close window"),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     , "Toggle floating mode"),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, "Move selected window to main position"),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        , "Move selected window to next screen"),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end, "Redraw selected window")
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
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     maximized_vertical   = false,
                     maximized_horizontal = false,
                     size_hints_honor = false,
                     buttons = clientbuttons } },
    { rule = { class = "Conky" },
      properties = { floating = true, sticky = true } },
    { rule = { instance = "Navigator" },
      properties = { tag = tags[1][1] } },
    { rule = { instance = "Mail" },
      properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
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

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

