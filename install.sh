#!/usr/bin/env bash
# Copy this repo into ~/.claude. Never touches .credentials.json.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DEST/hooks" "$DEST/skills"

# Back up files we overwrite.
for f in CLAUDE.md settings.json; do
  if [ -f "$DEST/$f" ]; then
    cp "$DEST/$f" "$DEST/$f.bak-$STAMP"
  fi
done

cp "$SRC/CLAUDE.md" "$SRC/settings.json" "$DEST/"
cp -R "$SRC/hooks/." "$DEST/hooks/"
cp -R "$SRC/skills/." "$DEST/skills/"
chmod +x "$DEST"/hooks/*

# gstack is not vendored. Print clone steps if missing.
if [ ! -d "$DEST/skills/gstack" ] && command -v git >/dev/null 2>&1; then
  echo "gstack not found. Clone with:"
  echo "  git clone https://github.com/garrytan/gstack.git \"$DEST/skills/gstack\" && cd \"$DEST/skills/gstack\" && ./setup"
fi

echo "Installed to $DEST (backups: *.bak-$STAMP)."
