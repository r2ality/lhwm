#!/bin/sh
# Install NVWM as a login session: the binary (if not installed yet), the
# nvwm-session wrapper and the xsessions desktop entry that every X11
# greeter (SDDM, LightDM, GDM, greetd/tuigreet) reads.
#
# Usage: scripts/install-session.sh
# Re-runs itself through sudo/doas when not started as root.
# Override paths with PREFIX=... and XSESSIONS=... if needed.
set -eu

PREFIX="${PREFIX:-/usr/local}"
XSESSIONS="${XSESSIONS:-/usr/share/xsessions}"

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo PREFIX="$PREFIX" XSESSIONS="$XSESSIONS" "$0" "$@"
    elif command -v doas >/dev/null 2>&1; then
        exec doas "$0" "$@"
    else
        echo "run as root (no sudo/doas found)" >&2
        exit 1
    fi
fi

# 1. the nvwm binary: prefer the installed one, else install the local build
BIN="$(command -v nvwm 2>/dev/null || true)"
if [ -z "$BIN" ]; then
    HERE="$(cd "$(dirname "$0")/.." && pwd)"
    if [ ! -x "$HERE/nvwm" ]; then
        echo "nvwm is neither installed nor built - run 'make' first" >&2
        exit 1
    fi
    mkdir -p "$PREFIX/bin" /etc/nvwm
    install -m 755 "$HERE/nvwm" "$PREFIX/bin/nvwm"
    [ -f /etc/nvwm/config.conf ] || install -m 644 "$HERE/config.conf" /etc/nvwm/config.conf
    BIN="$PREFIX/bin/nvwm"
fi

# 2. session wrapper: session env + dbus + audio, then NVWM.
#    Greeters should start this, never the bare nvwm binary.
cat > "$PREFIX/bin/nvwm-session" <<'EOF'
#!/bin/sh
export XDG_CURRENT_DESKTOP=nvwm
export XDG_SESSION_DESKTOP=nvwm
export XDG_SESSION_TYPE=x11

exec dbus-run-session sh -lc '
  command -v pipewire >/dev/null 2>&1 && pipewire &
  command -v wireplumber >/dev/null 2>&1 && wireplumber &
  exec nvwm
'
EOF
chmod 755 "$PREFIX/bin/nvwm-session"

# 3. xsessions entry: the session list every X11 greeter shows
mkdir -p "$XSESSIONS"
cat > "$XSESSIONS/nvwm.desktop" <<EOF
[Desktop Entry]
Name=NVWM
Comment=Neovim Window Manager
Exec=$PREFIX/bin/nvwm-session
TryExec=$BIN
Type=XSession
DesktopNames=nvwm
EOF

echo "installed: $PREFIX/bin/nvwm-session"
echo "installed: $XSESSIONS/nvwm.desktop"
echo "NVWM will appear in your greeter's session list at the next login screen."
