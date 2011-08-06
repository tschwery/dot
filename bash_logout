# ~/.bash_logout: executed by bash(1) when login shell exits.

# print how much time was wasted in front of this terminal session
printf "Was logged in for: %d hours %d mins %d sec\n" `expr $SECONDS / 3600` `expr $SECONDS % 3600 / 60` `expr $SECONDS % 60`
sleep 5

# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q || [ -x /usr/bin/clear ] && /usr/bin/clear
fi
