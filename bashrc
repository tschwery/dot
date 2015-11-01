# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

export HISTSIZE=5000

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Colors
RED='\[\033[01;31m\]'
GREEN='\[\033[01;32m\]'
YELLOW='\[\033[01;33m\]'
BLUE='\[\033[01;34m\]'
PURPLE='\[\033[01;35m\]'
CYAN='\[\033[01;36m\]'
WHITE='\[\033[01;37m\]'
NIL='\[\033[00m\]'

set_prompt() {
    reta=$?
    if [ $reta -ne 0 ]; then ret="${RED}($reta)"; else ret=""; fi

    command="${BLUE}\!"

    ucolor="${GREEN}"
    if [ $UID -lt 1000 ]; then ucolor="${RED}"; fi

    user="${ucolor}\u"
    host="${ucolor}\h"

    path="${BLUE}\w"

    end="${CYAN} $ ${NIL}"

    PS1="${command}${ret}${GREEN}@${host}:${path}${end}"

    title="${HOSTNAME}: ${PWD} ($reta)"
    printf "\e]2;%s\a" "$title"
}

PROMPT_COMMAND=set_prompt

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Function definitions.
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# enable color support
if [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b`"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

if [ -f ~/.bash_completion ]; then
    . ~/.bash_completion
fi

export MANPAGER="/usr/bin/most -s"

PATH="$HOME/.local/bin/:$PATH"
export PATH

if [ -f ~/.bash_local ]; then
    . ~/.bash_local
fi
