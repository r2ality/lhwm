#!/bin/sh
# Install holywm as a login session: the binary (if not installed yet), the
# holywm-session wrapper and the xsessions desktop entry that every X11
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

# 1. the holywm binary: prefer the installed one, else install the local build
BIN="$(command -v holywm 2>/dev/null || true)"
if [ -z "$BIN" ]; then
    HERE="$(cd "$(dirname "$0")/.." && pwd)"
    if [ ! -x "$HERE/holywm" ]; then
        echo "holywm is neither installed nor built - run 'make' first" >&2
        exit 1
    fi
    mkdir -p "$PREFIX/bin" /etc/holywm
    install -m 755 "$HERE/holywm" "$PREFIX/bin/holywm"
    [ -f /etc/holywm/config.conf ] || install -m 644 "$HERE/config.conf" /etc/holywm/config.conf
    BIN="$PREFIX/bin/holywm"
fi

# 2. session wrapper: session env + dbus + audio, then holywm.
#    Greeters should start this, never the bare holywm binary.
cat > "$PREFIX/bin/holywm-session" <<'EOF'
#!/bin/sh
export XDG_CURRENT_DESKTOP=holywm
export XDG_SESSION_DESKTOP=holywm
export XDG_SESSION_TYPE=x11

exec dbus-run-session sh -lc '
  command -v pipewire >/dev/null 2>&1 && pipewire &
  command -v wireplumber >/dev/null 2>&1 && wireplumber &
  exec holywm
'
EOF
chmod 755 "$PREFIX/bin/holywm-session"

# 3. xsessions entry: the session list every X11 greeter shows
mkdir -p "$XSESSIONS"
cat > "$XSESSIONS/holywm.desktop" <<EOF
[Desktop Entry]
Name=holywm
Comment=HolyC Window Manager
Exec=$PREFIX/bin/holywm-session
TryExec=$BIN
Type=XSession
DesktopNames=holywm
EOF

echo "installed: $PREFIX/bin/holywm-session"
echo "installed: $XSESSIONS/holywm.desktop"
echo "holywm will appear in your greeter's session list at the next login screen."
