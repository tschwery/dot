-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")

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
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Battery widget --------------------------------------------------
function batteryInfo(bwidget, adapter, popup)
    local fcur = io.open(adapter.."/energy_now")
    local fcap = io.open(adapter.."/energy_full")
    local fsta = io.open(adapter.."/status")

    local cur = fcur:read()
    local cap = fcap:read()
    local sta = fsta:read()
    if cap == nil then
        cap = math.huge
    else
        cap = tonumber(cap)
    end
    cur = tonumber(cur)

    local battery = (100 * cur) / cap

    fcur:close()
    fcap:close()
    fsta:close()

    local dir = " "

    if sta:match("Charging") then
        dir = "⚡"
    elseif sta:match("Discharging") then
        dir = "🔋"
        if battery < 10 and popup then
            naughty.notify({ title      = "Battery " .. adapter .. " Warning"
                           , text       = "Battery low! " .. battery .. "% left!"
                           , timeout    = 5
                           , position   = "top_right"
                           , fg         = beautiful.fg_focus
                           , bg         = beautiful.bg_focus
                           })
        end
    else
        dir = "="
    end
    local indicator = ""
    local battery_ten = math.floor(battery / 10)
    for f = 1,battery_ten do
        indicator = indicator .. "<span foreground='" .. ( beautiful.widget_color_battery or '#cc3333' ).. "'>♥</span>"
    end
    for f = battery_ten,9 do
        indicator = indicator .. "♡"
    end

    bwidget:set_markup(dir .. indicator)
end

batt_widgets = {}
local power_supply_prefix = "/sys/class/power_supply/"
local power_supply_list = io.popen('ls ' .. power_supply_prefix .. '*/energy_now'):lines()
for battery in power_supply_list do
    local battery_widget = wibox.widget.textbox()
    battery_widget:set_align("right")

    local p_length = string.len(power_supply_prefix) + 1
    local s_length = string.find(battery, '/', p_length)
    local adapter = string.sub(battery, 1, s_length)

    local battery_timer = gears.timer({timeout = 20})
    battery_timer:connect_signal("timeout", function()
        batteryInfo(battery_widget, adapter, #batt_widgets == 0)
    end)
    battery_timer:start()
    batteryInfo(battery_widget, adapter, true)

    batt_widgets[#batt_widgets + 1] = battery_widget
end
-- }}}

-- {{{ Coretemp --------------------------------------------------------
function thermal_information(twidget, thermal_zone)
    local fcur = io.open(thermal_zone.."/temp")
    local cur = fcur:read()

    local coretemp_now = tonumber(cur) / 1000

    twidget:set_text(math.floor(coretemp_now) .. "°C")
end

tempicon = wibox.widget.imagebox(beautiful.widget_temp)
temp_widgets = {}

local thermal_zone_prefix = "/sys/class/thermal/"
local thermal_zone_list = io.popen('ls ' .. thermal_zone_prefix .. '*/temp'):lines()

for thermal_sensor in thermal_zone_list do
    local f = io.open(thermal_sensor)
    -- We filter out thermal zones that error out
    local t = f:read("*all")
    if tonumber(t) ~= nil then
        local temp_widget = wibox.widget.textbox()
        temp_widget:set_align("right")

        local p_length = string.len(thermal_zone_prefix) + 1
        local s_length = string.find(thermal_sensor, '/', p_length)
        local thermal_zone = string.sub(thermal_sensor, 1, s_length)

        local temperature_timer = gears.timer({timeout = 20})
        temperature_timer:connect_signal("timeout", function()
            thermal_information(temp_widget, thermal_zone)
        end)
        temperature_timer:start()
        thermal_information(temp_widget, thermal_zone)

        temp_widgets[#temp_widgets + 1] = temp_widget
    end
end
-- }}}


-- {{{ Sound widget ----------------------------------------------------
local pulse_command = "pacmd"
local pulse_mixer = "pavucontrol"

function pulse_sink_default(dumpLines)
    local pulse_sink = string.match(dumpLines, "set%-default%-sink ([^\n]+)")
    return pulse_sink
end

function pulse_volume_current(dumpLines)
    local default_sink = pulse_sink_default(dumpLines)
    local pulse_volume = -1

    for sink, value in string.gmatch(dumpLines, "set%-sink%-volume ([^%s]+) (0x%x+)") do
        if sink == default_sink then
            pulse_volume = tonumber(value) / 0x10000
        end
    end

    local m = "no"
    for sink, value in string.gmatch(dumpLines, "set%-sink%-mute ([^%s]+) (%a+)") do
        if sink == default_sink then
            m = value
        end
    end

    if (m == "yes") then
         pulse_volume = 0
    end

    return pulse_volume
end

function pulse_volume_widget(swidget)
    local f = io.popen(pulse_command .. " dump")

    if f == nil then
        return false
    end

    local fout = f:read("*a")
    local pulse_sink = pulse_sink_default(fout)
    local pulse_volume = pulse_volume_current(fout)

    local indicator = ""

    if pulse_volume >= 0 then
        local sound_ten = math.ceil(pulse_volume * 10)
        for f = 1,sound_ten do
            indicator = indicator .. "<span foreground='" .. ( beautiful.widget_color_sound or '#3939e5' ) .. "'>🔉</span>"
        end
        for f = sound_ten,9 do
            indicator = indicator .. "🔊"
        end
    end

    swidget:set_markup(indicator)
end

local sound_widget = wibox.widget.textbox()
sound_widget:set_align("right")
sound_widget:buttons(awful.util.table.join(
                        awful.button({ }, 1, function () pulse_volume_set("mute") end),
                        awful.button({ }, 3, function () awful.spawn.with_shell( pulse_mixer ) end),
                        awful.button({ }, 4, function () pulse_volume_set("up") end),
                        awful.button({ }, 5, function () pulse_volume_set("down") end)
                        )
                    )

local sound_timer = gears.timer({timeout = 20})
sound_timer:connect_signal("timeout", function()
    pulse_volume_widget(sound_widget)
end)
sound_timer:start()
pulse_volume_widget(sound_widget)

function pulse_volume_set(action)
    local f = io.popen(pulse_command .. " dump")

    if f == nil then
        return false
    end

    local fout = f:read("*a")

    local pulse_sink = pulse_sink_default(fout)

    if pulse_sink == nil then
        naughty.notify({ title = "PulseAudio", text = "No default sink available for volume." .. fout})
        return nil
    end

    local pulse_volume = pulse_volume_current(fout)

    if action == "up" then
        pulse_volume = pulse_volume + 0.1
    elseif action == "down" then
        pulse_volume = pulse_volume - 0.1
    elseif action == "mute" then
        pulse_volume = 0
    end

    if pulse_volume > 1 then
        pulse_volume = 1
    end

    if pulse_volume < 0 then
        pulse_volume = 0
    end

    local pulse_volume_int = pulse_volume * 0x10000

    io.popen(pulse_command .. " set-sink-volume " .. pulse_sink .. " " .. string.format("0x%x", math.floor(pulse_volume_int)))

    pulse_volume_widget(sound_widget)
end
-- }}}

-- {{{ Helper functions ------------------------------------------------
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

-- Lock mechanism
function screen_lock ( blackout )
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

    if (blackout == nil) then
        blackout = 5
    end

    local lock_timer = gears.timer { timeout = 1 }
    local soff_timer = gears.timer { timeout = blackout }

    lock_timer:connect_signal("timeout", function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.local/bin/alock" .. " " .. auth .. " " .. back .. " " .. curs)
        lock_timer:stop()
    end)
    soff_timer:connect_signal("timeout", function()
        awful.spawn.with_shell("/usr/bin/xset dpms force off")
        soff_timer:stop()
    end)

    lock_timer:start()
    if ( blackout > 0 ) then
        soff_timer:start()
    end
end

-- Sleep, shutdown and reboot actions
function power_function (action, menu)
    naughty.notify({ title = "Menu", text = menu, timeout = 2 })
    if (action == "Suspend") then
        screen_lock(-1)
        local sleep_timer = gears.timer { timeout = 2 }
        sleep_timer:connect_signal("timeout", function()
            sleep_timer:stop()
            io.popen('systemctl suspend')
        end)
        sleep_timer:start()
    elseif (action == "Hibernate") then
        screen_lock(-1)
        local sleep_timer = gears.timer { timeout = 2 }
        sleep_timer:connect_signal("timeout", function()
            sleep_timer:stop()
            io.popen('systemctl hibernate')
        end)
        sleep_timer:start()
    else
         naughty.notify({ title = "Unknown error", text = "Unknown action " .. action .. "."})
    end
end

-- }}}

-- {{{ Wallpaper
local wp_timeout = 600
local wp_path = os.getenv("HOME") .. "/Divers/Wallpapers/"
local wp_init = function ()
    local walls_iterator = io.popen('ls "' .. wp_path .. '"'):lines()
    walls = {}
    for v in walls_iterator do
        walls[#walls + 1] = v
    end
end

math.randomseed( os.time() )

wp_init()

beautiful.wallpaper = function(s)
    local wall_number = math.random(1,#walls)
    local back =  wp_path .. walls[wall_number]
    return back
end
-- }}}


-- {{{ Menu ------------------------------------------------------------
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mypowermenu = {
    { "Suspend",  function() power_function("Suspend") end },
    { "Hibernate",  function() power_function("Hibernate") end }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal },
                                    { "power", mypowermenu }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar -----------------------------------------------------------
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Separator
spr = wibox.widget.textbox('|')

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
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

local function set_wallpaper(s)
    return function()
        -- Wallpaper
        if beautiful.wallpaper then
            local wallpaper = beautiful.wallpaper
            -- If wallpaper is a function, call it with the screen
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(s)
            end
            gears.wallpaper.maximized(wallpaper, s, false)
        end
    end
end

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)()
    
    wp_timer = gears.timer { timeout = wp_timeout }
    wp_timer:connect_signal("timeout", set_wallpaper(s))
    wp_timer:start()
    
    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }, s, awful.layout.layouts[3])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })
    
    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(sound_widget)
    right_layout:add(spr)
    for i,batt_widget in ipairs(batt_widgets) do
        right_layout:add(batt_widget)
        right_layout:add(spr)
    end
    right_layout:add(tempicon)
    for i,temp_widget in ipairs(temp_widgets) do
        right_layout:add(temp_widget)
        right_layout:add(spr)
    end
    right_layout:add(mytextclock)
    right_layout:add(spr)
    right_layout:add(s.mylayoutbox)

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        right_layout, -- Right widget
    }
end)
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
    awful.key({ modkey,           }, "F1",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey            }, "F12",    function() screen_lock() end,
              {description="lock screen", group="awesome"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"}),
    awful.key({         }, "XF86AudioRaiseVolume",  function() pulse_volume_set("up")   end,
        {description = "Raise PulseAudio general volume", group="sound"}),
    awful.key({         }, "XF86AudioLowerVolume",  function() pulse_volume_set("down") end,
        {description = "Lower PulseAudio general volume", group="sound"}),
    awful.key({         }, "XF86AudioMute",         function() pulse_volume_set("mute") end,
        {description = "Mute PulseAudio general mixer", group="sound"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false,
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "sun-awt-X11-XFramePeer", -- Java applications
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Set Firefox to always map on the tag named "2" on screen 1.
       { rule = { instance = "Navigator" },
         properties = { screen = 1, tag = "1" } },
       { rule = { instance = "Mail" },
         properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
