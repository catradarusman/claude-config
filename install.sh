#!/usr/bin/env bash
# Link this repo into ~/.claude. Never touches .credentials.json or skills/gstack.
# Safe to run more than once.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd -P)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP="$DEST/backup-$(date +%Y-%m-%d)"

mkdir -p "$DEST/skills"

# Symlink CLAUDE.md, settings.json, hooks. Back up real files first.
for name in CLAUDE.md settings.json hooks; do
  target="$DEST/$name"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$SRC/$name" ]; then
    echo "ok      $name"
    continue
  fi
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$BACKUP"
    dst="$BACKUP/$name"
    [ -e "$dst" ] && dst="$dst.$(date +%H%M%S)"
    mv "$target" "$dst"
    echo "backup  $name -> $dst"
  fi
  ln -sfn "$SRC/$name" "$target"
  echo "link    $name -> $SRC/$name"
done
chmod +x "$SRC"/hooks/*

# Copy skills. Skip gstack and skills owned elsewhere: symlinks,
# gstack-owned dirs, or dirs holding gstack-rendered links.
copied=0 skipped=0
for s in "$SRC"/skills/*; do
  d="$DEST/skills/${s##*/}"
  if [ "${s##*/}" = "gstack" ] || [ -L "$d" ] || [ -f "$d/.gstack-owned" ] \
     || [ -n "$(find "$d" -type l 2>/dev/null | head -n1)" ]; then
    skipped=$((skipped + 1))
    continue
  fi
  cp -R "$s" "$DEST/skills/"
  copied=$((copied + 1))
done
echo "skills  copied $copied, skipped $skipped (owned elsewhere)"

# gstack is not vendored. Print clone steps if missing.
if [ ! -d "$DEST/skills/gstack" ] && command -v git >/dev/null 2>&1; then
  echo "gstack not found. Clone with:"
  echo "  git clone https://github.com/garrytan/gstack.git \"$DEST/skills/gstack\" && cd \"$DEST/skills/gstack\" && ./setup"
fi

echo "Installed to $DEST."
