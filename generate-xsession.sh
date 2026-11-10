#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUTPUT=${1:-"$ROOT/lhwm.nix"}

# Resolve relative output paths against the caller's working directory.
case "$OUTPUT" in
  /*) ;;
  *) OUTPUT="$(pwd)/$OUTPUT" ;;
esac

# An already-built package can be supplied for offline/reproducible use:
# LHWM_PACKAGE=/nix/store/...-lhwm-0.1.1 ./generate-xsession.sh
if [ -n "${LHWM_PACKAGE:-}" ]; then
  PACKAGE_PATH=$LHWM_PACKAGE
else
  if ! command -v nix >/dev/null 2>&1; then
    echo "error: nix is required to build LHWM; alternatively set LHWM_PACKAGE to an existing LHWM store path" >&2
    exit 1
  fi
  echo "Building LHWM package from $ROOT ..." >&2
  PACKAGE_PATH=$(cd "$ROOT" && nix build .#lhwm --no-link --print-out-paths)
fi

case "$PACKAGE_PATH" in
  /nix/store/*) ;;
  *)
    echo "error: expected an LHWM package path under /nix/store, got: $PACKAGE_PATH" >&2
    exit 1
    ;;
esac

if [ ! -x "$PACKAGE_PATH/bin/lhwm" ]; then
  echo "error: $PACKAGE_PATH does not contain an executable bin/lhwm" >&2
  exit 1
fi
if [ ! -f "$PACKAGE_PATH/share/lhwm/lhwm.conf" ]; then
  echo "error: $PACKAGE_PATH does not contain share/lhwm/lhwm.conf" >&2
  exit 1
fi

mkdir -p "$(dirname -- "$OUTPUT")"
sed "s|@LHWM_PACKAGE@|$PACKAGE_PATH|g" \
  "$ROOT/nix/lhwm-session.nix.in" > "$OUTPUT"

printf 'Generated %s\n' "$OUTPUT"
printf 'LHWM package: %s\n' "$PACKAGE_PATH"
printf '\nNext: sudo cp %s /etc/nixos/lhwm.nix\n' "$OUTPUT"
printf 'Then add ./lhwm.nix to the imports list in /etc/nixos/configuration.nix.\n'
