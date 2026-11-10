#!/bin/sh
# Optional extras. Copy this idea into ~/.xprofile or a personal session
# wrapper. Nothing here is launched by LHWM itself.

if command -v picom >/dev/null 2>&1; then
    picom --config "$HOME/.config/picom/picom.conf" &
fi

WALL="$HOME/Pictures/Wallpapers/current.jpg"
if [ -f "$WALL" ]; then
    if command -v xwallpaper >/dev/null 2>&1; then
        xwallpaper --zoom "$WALL"
    elif command -v feh >/dev/null 2>&1; then
        feh --bg-fill "$WALL"
    fi
fi

exec lhwm
