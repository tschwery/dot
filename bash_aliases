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

alias valgrind_memory='valgrind --leak-check=full --show-reachable=yes'
