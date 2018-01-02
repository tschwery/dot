--[[
                                             
     Valdor Awesome custom theme, derived from
     Powerarrow Darker Awesome WM config 2.0 
     github.com/copycat-killer               
                                             
--]]

theme                               = {}

themes_dir                          = os.getenv("HOME") .. "/.config/awesome/themes/valdor"
theme.wallpaper                     = os.getenv("HOME") .. "/Pictures/Wallpapers/rore_-_Debian_Moonlight.png"

theme.wall_dir                      = os.getenv("HOME") .. "/Divers/Wallpapers"
theme.lock_dir                      = os.getenv("HOME") .. "/Divers/Lockscreens"

theme.font                          = "Inconsolata 8"
theme.fg_normal                     = "#AAAAAA"
theme.fg_focus                      = "#F0F0F0"
theme.fg_urgent                     = "#CC9393"
theme.bg_normal                     = "#202020"
theme.bg_focus                      = "#535d6c"
theme.bg_urgent                     = "#ff0000"
theme.border_width                  = "2"
theme.border_normal                 = "#101A20"
theme.border_focus                  = "#9090A0"
theme.border_marked                 = "#91231C"
theme.titlebar_bg_focus             = "#FFFFFF"
theme.titlebar_bg_normal            = "#FFFFFF"
theme.taglist_fg_focus              = "#909090"
theme.tasklist_bg_focus             = "#1A1A1A"
theme.tasklist_fg_focus             = "#D8D8D8"
theme.textbox_widget_margin_top     = 1
theme.notify_fg                     = theme.fg_normal
theme.notify_bg                     = theme.bg_normal
theme.notify_border                 = theme.border_focus
theme.awful_widget_height           = 14
theme.awful_widget_margin_top       = 2
theme.mouse_finder_color            = "#CC9393"
theme.menu_height                   = "15"
theme.menu_width                    = "140"

theme.menu_submenu_icon             = themes_dir .. "/icons/submenu.png"
theme.taglist_squares_sel           = themes_dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel         = themes_dir .. "/icons/square_unsel.png"

theme.layout_fairh                  = "/usr/share/awesome/themes/default/layouts/fairhw.png"
theme.layout_fairv                  = "/usr/share/awesome/themes/default/layouts/fairvw.png"
theme.layout_floating               = "/usr/share/awesome/themes/default/layouts/floatingw.png"
theme.layout_magnifier              = "/usr/share/awesome/themes/default/layouts/magnifierw.png"
theme.layout_max                    = "/usr/share/awesome/themes/default/layouts/maxw.png"
theme.layout_fullscreen             = "/usr/share/awesome/themes/default/layouts/fullscreenw.png"
theme.layout_tilebottom             = "/usr/share/awesome/themes/default/layouts/tilebottomw.png"
theme.layout_tileleft               = "/usr/share/awesome/themes/default/layouts/tileleftw.png"
theme.layout_tile                   = "/usr/share/awesome/themes/default/layouts/tilew.png"
theme.layout_tiletop                = "/usr/share/awesome/themes/default/layouts/tiletopw.png"
theme.layout_spiral                 = "/usr/share/awesome/themes/default/layouts/spiralw.png"
theme.layout_dwindle                = "/usr/share/awesome/themes/default/layouts/dwindlew.png"
theme.layout_cornernw               = "/usr/share/awesome/themes/default/layouts/cornernww.png"
theme.layout_cornerne               = "/usr/share/awesome/themes/default/layouts/cornernew.png"
theme.layout_cornersw               = "/usr/share/awesome/themes/default/layouts/cornersww.png"
theme.layout_cornerse               = "/usr/share/awesome/themes/default/layouts/cornersew.png"

theme.arrl                          = themes_dir .. "/icons/arrl.png"
theme.arrl_dl                       = themes_dir .. "/icons/arrl_dl.png"
theme.arrl_ld                       = themes_dir .. "/icons/arrl_ld.png"

theme.widget_color_battery          = "#cc3333"
theme.widget_color_sound            = "#3939e5"

theme.widget_ac                     = themes_dir .. "/icons/ac.png"
theme.widget_battery                = themes_dir .. "/icons/battery.png"
theme.widget_battery_low            = themes_dir .. "/icons/battery_low.png"
theme.widget_battery_empty          = themes_dir .. "/icons/battery_empty.png"
theme.widget_mem                    = themes_dir .. "/icons/mem.png"
theme.widget_cpu                    = themes_dir .. "/icons/cpu.png"
theme.widget_temp                   = themes_dir .. "/icons/temp.png"
theme.widget_net                    = themes_dir .. "/icons/net.png"
theme.widget_hdd                    = themes_dir .. "/icons/hdd.png"
theme.widget_music                  = themes_dir .. "/icons/note.png"
theme.widget_music_on               = themes_dir .. "/icons/note_on.png"
theme.widget_vol                    = themes_dir .. "/icons/vol.png"
theme.widget_vol_low                = themes_dir .. "/icons/vol_low.png"
theme.widget_vol_no                 = themes_dir .. "/icons/vol_no.png"
theme.widget_vol_mute               = themes_dir .. "/icons/vol_mute.png"
theme.widget_mail                   = themes_dir .. "/icons/mail.png"
theme.widget_mail_on                = themes_dir .. "/icons/mail_on.png"

theme.tasklist_disable_icon         = true
theme.tasklist_floating             = ""
theme.tasklist_maximized_horizontal = ""
theme.tasklist_maximized_vertical   = ""

theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"

return theme
