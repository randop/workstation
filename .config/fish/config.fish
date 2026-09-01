if status is-interactive
    ## --- launch ssh agent
    eval (ssh-agent -c) >/dev/null
    set -gx SSH_AUTH_SOCK $SSH_AUTH_SOCK
    set -gx SSH_AGENT_PID $SSH_AGENT_PID
end

# terminal compatibility
set -gx TERM xterm-256color

# required by gpg agent pinentry helper
set -gx GPG_TTY (tty)

# use custom ssh agent passphrase helper
set -gx SSH_ASKPASS "$HOME/.local/bin/methuselah-ssh-wrapper"
set -gx SSH_ASKPASS_REQUIRE force

# suppress welcome message
set fish_greeting
