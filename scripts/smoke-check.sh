#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
sh -n build.sh generate-xsession.sh scripts/build.sh scripts/lhwm-session.in examples/session-extra.sh
[ -s src/lhwm.HC ]
[ -s src/x11.HH ]
[ -s config/lhwm.conf ]
grep -q 'Mod4+Return' config/lhwm.conf
grep -q 'Mod4+Shift+q' config/lhwm.conf
grep -q 'Mod4+r reload' config/lhwm.conf
grep -q '^bind = Mod4+d spawn dmenu_run$' config/lhwm.conf
! grep -q 'launcher_command' config/lhwm.conf
grep -q 'bar_enabled = true' config/lhwm.conf
grep -q 'bar_border_color = #45475a' config/lhwm.conf
grep -q 'workspace_active_border = #d8ad4a' config/lhwm.conf
grep -q 'config.HC' src/lhwm.HC
grep -q 'write_default_config' src/lhwm.HC
grep -q 'make_config_dir' src/lhwm.HC
grep -q 'parse_hc_line' src/lhwm.HC
grep -q 'window_wants_float' src/lhwm.HC
grep -q '_NET_WM_WINDOW_TYPE_DIALOG' src/lhwm.HC
grep -q 'XGetTransientForHint' src/x11.HH
grep -q 'RULE_WORKSPACE' src/lhwm.HC
grep -q 'focus_follows' src/lhwm.HC
for n in 1 2 3 4 5 6 7 8 9; do
  grep -q "^bind = Mod4+$n workspace $n$" config/lhwm.conf
  grep -q "^bind = Mod4+Shift+$n move_workspace $n$" config/lhwm.conf
  grep -q "add_binding(\"Mod4+$n\", \"workspace\", \"$n\")" src/lhwm.HC
done
grep -q 'XDrawRectangle' src/lhwm.HC
grep -q 'XSetLineAttributes' src/lhwm.HC
grep -q 'XUnmapWindow' src/lhwm.HC
grep -q 'workspace_hitbox' src/lhwm.HC
grep -q 'ButtonPressMask' src/lhwm.HC
grep -q 'bar_border_color' src/lhwm.HC
grep -q 'workspace_active_border' src/lhwm.HC
grep -q 'strftime(formatted, 128, clock_format, time_info)' src/lhwm.HC
grep -q 'localtime(&now)' src/lhwm.HC
grep -q 'XConnectionNumber(dpy)' src/lhwm.HC
grep -q 'poll(&x_poll, 1, wait_ms)' src/lhwm.HC
grep -q 'if (running && now >= next_clock_tick)' src/lhwm.HC
grep -q 'next_clock_tick = now + clock_update_interval' src/lhwm.HC
grep -q 'clock_format = %a %d %b  %H:%M' config/lhwm.conf
grep -q 'clock_update_interval = 1' config/lhwm.conf
grep -q 'XLoadFont(dpy, "fixed")' src/lhwm.HC
grep -q 'XListFonts' src/lhwm.HC
grep -q 'bar_font_name' src/lhwm.HC
grep -q 'binds\[i\]\.keycode == key->keycode' src/lhwm.HC
grep -q 'root, False, GrabModeAsync, GrabModeAsync' src/lhwm.HC
grep -q 'XGrabButton(dpy, Button1, Mod4Mask | locks\[i\], win, False' src/lhwm.HC
grep -q 'XGrabButton(dpy, Button3, Mod4Mask | locks\[i\], win, False' src/lhwm.HC
! grep -q 'bar_icon' src/lhwm.HC config/lhwm.conf
grep -q 'EnterWindowMask' src/lhwm.HC
grep -q 'case EnterNotify' src/lhwm.HC
! grep -q 'StructureNotifyMask | ButtonPressMask' src/lhwm.HC
grep -q 'b->keycode = keycode' src/lhwm.HC
! grep -q 'binding->action, "launcher"' src/lhwm.HC
! grep -q 'launcher_command' src/lhwm.HC
! grep -q 'lhwm-clock.sh' flake.nix
grep -q 'pkgs.dmenu' nix/lhwm-session.nix.in
grep -q 'fonts.packages = \[ pkgs.font-misc-misc \];' nix/lhwm-session.nix.in
grep -q 'pkgs.dmenu' nix/nixos-module.nix
grep -q 'fonts.packages = \[ pkgs.font-misc-misc \];' nix/nixos-module.nix
grep -q '#link <X11>' src/x11.HH
! grep -Eq '\?.*:' src/lhwm.HC
grep -Fq 'XSetErrorHandler((&xerror)(U8 *));' src/lhwm.HC
grep -Fq 'signal(SIGCHLD, SIG_IGN(U8 *));' src/lhwm.HC
grep -Fq 'pkgs.libx11' flake.nix
grep -Fq 'buildInputs = [ pkgs.libx11 hcc ];' flake.nix
grep -Fq '"$out/bin/hcc" -lib tos --install-dir="$out" ./all.HC' flake.nix
grep -Fq 'src/holyc-lib/tos.HH' flake.nix
grep -Fq -- "-name 'libtos.*'" flake.nix
! grep -q 'pkgs.xorg.libX11' flake.nix
grep -q 'services.displayManager.sessionPackages = \[ lhwmSession \];' nix/lhwm-session.nix.in
grep -Fq 'providedSessions = [ "lhwm" ];' nix/lhwm-session.nix.in
grep -q 'nix build .#lhwm --no-link --print-out-paths' generate-xsession.sh
grep -q 'LHWM_PACKAGE' generate-xsession.sh

printf 'LHWM source, config.HC, window-rule, workspace, and native clock smoke checks passed.\n'
printf 'Note: this does not compile the HolyC core; run ./build.sh with hcc installed.\n'
