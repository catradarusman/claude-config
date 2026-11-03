# claude-config

My Claude Code setup: `CLAUDE.md`, `settings.json`, hooks, and skills.

## Install

```bash
git clone https://github.com/catradarusman/claude-config.git
cd claude-config
./install.sh
```

The script links `CLAUDE.md`, `settings.json`, and `hooks/` from `~/.claude` to this repo. Edit them here, then commit. If a real file is in the way, the script moves it to `~/.claude/backup-<date>/` first.

It copies `skills/` into `~/.claude/skills`. It skips `gstack` and any skill that is a symlink or managed by gstack. It never touches `.credentials.json`. You can run it again safely.

## What is here

- `CLAUDE.md`: global instructions for every project.
- `settings.json`: permissions, skill toggles, hooks, status line, plugins.
- `hooks/guard.py`: blocks a few destructive commands and edits to secret files. Needs `python3`.
- `skills/`: local skills.

## Not included

- `gstack`. It is large and has its own repo. Install it from https://github.com/garrytan/gstack. The Stop hook skips itself when gstack is missing.
- Plugins. Claude Code installs them from `enabledPlugins` and `extraKnownMarketplaces`. The status line needs the `caveman` plugin.
- Credentials, history, sessions, projects, and cache.
