#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
HCC=${HCC:-hcc}
OUTPUT=${1:-build/lhwm}
mkdir -p "$(dirname -- "$OUTPUT")"

if [ -n "${HCC_PREFIX:-}" ]; then
    "$HCC" --install-dir "$HCC_PREFIX" src/lhwm.HC -o "$OUTPUT"
else
    "$HCC" src/lhwm.HC -o "$OUTPUT"
fi
printf 'Built %s\n' "$OUTPUT"
