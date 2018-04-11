#------------------------------------------
#------------  General   ------------------
alias free="free -m"
alias df="df -Th"
alias feh="feh -Tdefault"
alias o="xdg-open"

#---- Listings
alias ls="ls --color=auto -hF --file-type"
alias la="ls --color=auto -ahF --file-type"
alias ll="ls --color=auto -lahF --file-type"

#---- Utilities
alias grep='grep --color=auto'

alias sapt='apt-cache search'
alias fapt='apt-file search'

alias nip='curl icanhazip.com'

alias cdiff='diff -wBy -W $COLUMNS'

alias issh='ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
alias iscp='scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
alias isftp='sftp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
alias ichrome='chromium --disable-web-security --ignore-certificate-errors'

alias valgrind_memory='valgrind --leak-check=full --show-reachable=yes'

alias netbeans_clean='rm ${HOME}/.netbeans/*/config/Windows2Local/Components/*'

alias noblank='xset -dpms; xset s off;'

alias net_eth1='sudo killall dhclient ; sudo dhclient wlan1 -r && sudo dhclient eth1 -v'
alias net_wlan1='sudo killall dhclient ; sudo dhclient eth1 -r && sudo dhclient wlan1 -v'

alias svdiff='svn --diff-cmd "diff" --extensions "-y -W $COLUMNS --suppress-common-lines" diff'

alias please='sudo $(history -p \!\!)'
