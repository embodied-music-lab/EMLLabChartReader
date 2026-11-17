#!/usr/bin/env bash
# Builds the installable plugin zip from the plugin folder.
# The plugin name is declared in NAME below; the version in the plugin's VERSION file.
# Usage: bash build.sh            build dist/plugin_<NAME>/ and dist/plugin_<NAME>.zip
#        PRAAT=/path/to/praat bash build.sh check
#                              also install into a scratch home and confirm
#                              that Praat runs the plugin's setup without error
set -euo pipefail
NAME=EMLLabChartReader                 # the one place the plugin name is declared
HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="$HERE/dist"
PLUGIN="plugin_$NAME"
SRC="$HERE/$PLUGIN"

# The script's settings folder name must match the plugin name.
grep -q "^toolName\$ = \"$NAME\"$" "$SRC/scripts/emlLabChartReader.praat" \
  || { echo "build: toolName\$ in the script does not match NAME=$NAME" >&2; exit 1; }

# The VERSION file is the one place the version is declared; every header must match it.
VERSION=$(tr -d '[:space:]' < "$SRC/VERSION")
echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || { echo "build: $PLUGIN/VERSION must hold digits and periods, like 0.1.0" >&2; exit 1; }
for f in "$SRC/setup.praat" "$SRC/scripts/emlLabChartReader.praat"; do
  grep -q "^# Version: $VERSION$" "$f" \
    || { echo "build: $(basename "$f") header does not say Version: $VERSION" >&2; exit 1; }
done

rm -rf "$DIST"
mkdir -p "$DIST/$PLUGIN"
cp -R "$SRC/." "$DIST/$PLUGIN/"
find "$DIST/$PLUGIN" -type d -exec chmod 0755 {} +
find "$DIST/$PLUGIN" -type f -exec chmod 0644 {} +
(cd "$DIST" && rm -f "$PLUGIN.zip" && zip -qrX "$PLUGIN.zip" "$PLUGIN")
echo "built $DIST/$PLUGIN and $DIST/$PLUGIN.zip (version $VERSION)"

if [ "${1:-}" = "check" ]; then
  : "${PRAAT:?set PRAAT to a Praat executable}"
  scratch="$(mktemp -d)"
  # Praat 7 reads plugins from ~/.config/praat (Linux); Praat 6 from ~/.praat-dir.
  for d in "$scratch/.config/praat" "$scratch/.praat-dir"; do mkdir -p "$d"; done
  version=$("$PRAAT" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  case "$version" in 6.*) target="$scratch/.praat-dir" ;; *) target="$scratch/.config/praat" ;; esac
  (cd "$scratch" && unzip -q "$DIST/$PLUGIN.zip" -d "$target")
  echo 'writeInfoLine: "started"' > "$scratch/start.praat"
  out=$(HOME="$scratch" "$PRAAT" --run "$scratch/start.praat" 2>&1)
  rm -rf "$scratch"
  if echo "$out" | grep -q "contains an error"; then echo "$out" >&2; echo "check: setup.praat failed" >&2; exit 1; fi
  echo "check: Praat $version ran $PLUGIN's setup.praat without error"
  echo "check: to confirm the menu entry, run tests/verify_install.sh (needs a display)"
fi
