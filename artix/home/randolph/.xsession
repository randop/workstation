#!/bin/sh
export XDG_CURRENT_DESKTOP=X-Generic
export TERM=xterm-256color
export PATH="$PATH:$HOME/.local/bin:$HOME/.local/share/flatpak/exports/bin:$HOME/opt/kitty/bin"
export EDITOR=vim

# Disable the X screensaver blanking
xset s off
xset s noblank

# Disable DPMS (monitor power off/standby/suspend)
xset -dpms

# window manager utilities
$HOME/.local/bin/xsbar &
$HOME/.local/bin/xwplus

# audio
killall pipewire
killall pipewire-pulse
killall wireplumber
pipewire &
sleep 1
pipewire-pulse &
sleep 1
wireplumber &

# auto-start applications
$HOME/opt/kitty/bin/kitty --class btop btop &
$HOME/opt/kitty/bin/kitty --class console &
$HOME/opt/kitty/bin/kitty --class neovim nvim ~/projects &
/usr/local/bin/st -c lazygit &

# launch dwm
exec dbus-launch --exit-with-session dwm
