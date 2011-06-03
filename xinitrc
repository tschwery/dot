#!/bin/bash

# Setting the bg
nitrogen --restore

# Add a path
PATH=$PATH:/home/valdor/.local/bin/:/home/valdor/EPFL/bin/
xdg-user-dirs-update

# Setting the screen dpi
xrandr --dpi 70

# Setting the touchpad parameters
synclient AccelFactor=0.12

# Binding some keys ...
xmodmap -e 'keycode 77 = ISO_Level3_Shift Num_Lock'

# Launching essential apps
clipit &
conky &
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

# invoke global X session script
. /etc/X11/Xsession
# Does not return ...
