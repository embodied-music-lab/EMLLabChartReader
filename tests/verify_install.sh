#!/usr/bin/env bash
# Installs dist/plugin_<NAME>.zip into a scratch home, starts GUI Praat on a
# virtual display, opens the Objects window's Open menu and checks that
# "Read LabChart binary file..." is listed. Linux only.
# Needs: Xvfb, xdotool, ImageMagick (import), tesseract.
# Usage: PRAAT=/path/to/full/praat bash tests/verify_install.sh   (run bash build.sh first)
set -uo pipefail
: "${PRAAT:?set PRAAT to a full (GUI) Praat executable}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ZIP=$(ls "$HERE"/../dist/plugin_*.zip | head -1)
scratch="$(mktemp -d)"
version=$("$PRAAT" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
case "$version" in 6.*) target="$scratch/.praat-dir" ;; *) target="$scratch/.config/praat" ;; esac
mkdir -p "$target" && unzip -q "$ZIP" -d "$target"
export DISPLAY=:97
rm -f /tmp/.X97-lock /tmp/.X11-unix/X97
Xvfb :97 -screen 0 1600x1200x24 >/dev/null 2>&1 & xvfb=$!
for i in $(seq 40); do xdotool getdisplaygeometry >/dev/null 2>&1 && break; sleep 0.25; done
HOME="$scratch" "$PRAAT" >/dev/null 2>&1 & praat=$!
w=""; for i in $(seq 80); do w=$(xdotool search --name "Praat Objects" 2>/dev/null | tail -1); [ -n "$w" ] && break; sleep 0.25; done
sleep 1
xdotool windowraise "$w"; sleep 0.5
import -window root -resize 300% "$scratch/window.png"
# the Open menu in the Objects window: the first word "Open" on screen
# (the capture is enlarged three times for OCR, so coordinates are divided by 3)
pos=$(tesseract "$scratch/window.png" - --psm 11 tsv 2>/dev/null \
      | awk -F'\t' 'NR > 1 && $12 == "Open" { print int(($7 + $9 / 2) / 3), int(($8 + $10 / 2) / 3); exit }')
xdotool mousemove $pos click 1
sleep 1
import -window root -resize 300% "$scratch/menu.png"
found=$(tesseract "$scratch/menu.png" - 2>/dev/null | grep -c "Read LabChart binary file")
kill $praat $xvfb 2>/dev/null
rm -rf "$scratch"
if [ "$found" -gt 0 ]; then echo "verify: Praat $version lists \"Read LabChart binary file...\""; else echo "verify: menu entry NOT found on Praat $version" >&2; exit 1; fi
