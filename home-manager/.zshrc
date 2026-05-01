# -*- mode: zsh; sh-basic-offset: 4; indent-tabs-mode: nil -*-

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=4000
SAVEHIST=1000
#bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

zellij_update_env_outside () {
    [[ -z "$1" ]] && printf "need session name\n" && return 1

    local session_name="$1"
    local session_file="$XDG_RUNTIME_DIR/zellij/session.${session_name}.env"
    # we want these vars defined everywhere (control sway via ssh)
    local vars=(
        DBUS_SESSION_BUS_ADDRESS
        DISPLAY
        NIXOS_OZONE_WL
        SSH_AGENT_PID
        SSH_AUTH_SOCK 
        SWAYSOCK
        WAYLAND_DISPLAY
        WINDOWID
        XCURSOR_SIZE
        XCURSOR_THEME
        XDG_CURRENT_DESKTOP
        XDG_SESSION_ID
        XDG_SESSION_TYPE )

    # we *don't* want to have host name show for local sessions so we want to unset these
    local exclusive_vars=(
        SSH_CONNECTION
        SSH_CLIENT
        SSH_TTY )

    declare -p $vars > "$session_file" 2>/dev/null

    for var in "${exclusive_vars[@]}"; do
        (declare -p $var 2>/dev/null || printf "unset %s\n" "$var") >> "$session_file"
    done
}

if [[ $(tty) != "/dev/tty6" # backdoor just incase something goes wrong
   && -n "$PS1"             # maybe useless?
   && ! "$TERM" =~ screen   # lets not make this modifier hell 
   && ! "$TERM" =~ tmux 
   && -z "$TMUX"
   && -z "$ZELLIJ"
   ]] ; then
    zellij_update_env_outside main
    exec zellij attach -c main
fi


if [[ -n "$ZELLIJ_SESSION_NAME"
   && -w  "$XDG_RUNTIME_DIR/zellij/session.$ZELLIJ_SESSION_NAME.env"
   ]]; then
    ZELLIJ_ENV_FILE="$XDG_RUNTIME_DIR/zellij/session.$ZELLIJ_SESSION_NAME.env"

    zellij_update_env_inside () {
    local modtime=$(stat -c %Y "$ZELLIJ_ENV_FILE")
    if [[ -z "$ZELLIJ_ENV_FILE_MODTIME" || $modtime > $ZELLIJ_ENV_FILE_MODTIME ]]; then
        source "$ZELLIJ_ENV_FILE"
        export ZELLIJ_ENV_FILE_MODTIME="$modtime"
        fi
    }
    
    add-zsh-hook precmd zellij_update_env_inside
fi
