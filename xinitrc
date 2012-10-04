#!/bin/bash

# Getting the config for rxvt
xrdb -merge ~/.Xresources

# Setting the bg
feh  --bg-fill "$HOME/Pictures/Wallpapers/rore_-_Debian_Moonlight.png"

# Add a path
PATH="$HOME/.local/bin/:$HOME/EPFL/bin/:$PATH"
xdg-user-dirs-update

# Setting the screen dpi
xrandr --dpi 70

# Setting the touchpad parameters
synclient AccelFactor=0.12

# Binding some keys ...
xmodmap -e 'keycode 77 = ISO_Level3_Shift Num_Lock'

# Launching essential apps
clipit &
conky -c /home/valdor/.conkyrc &
conky -c /home/valdor/.conkyrssrc &
mpd /home/valdor/.mpd/mpd.conf
xcompmgr &

# .. And some useful apps
firefox &
icedove &

# Set the audio volume
amixer set 'Headphone' 56
amixer set 'Speaker' 0
amixer set 'Master' 20

# Set the watch onto connection files
notify_connections &

# Autosync
lsyncd "$HOME/.lsyncrc"

# invoke global X session script
. /etc/X11/Xsession
# Does not return ...
