# claude-config

My Claude Code setup: `CLAUDE.md`, `settings.json`, hooks, and skills.

## Install

```bash
git clone https://github.com/catradarusman/claude-config.git
cd claude-config
./install.sh
```

The script copies files into `~/.claude`. It backs up your `CLAUDE.md` and `settings.json` first. It never touches `.credentials.json`.

## What is here

- `CLAUDE.md`: global instructions for every project.
- `settings.json`: permissions, skill toggles, hooks, status line, plugins.
- `hooks/guard.py`: blocks a few destructive commands and edits to secret files. Needs `python3`.
- `skills/`: local skills.

## Not included

- `gstack`. It is large and has its own repo. Install it from https://github.com/garrytan/gstack. The Stop hook skips itself when gstack is missing.
- Plugins. Claude Code installs them from `enabledPlugins` and `extraKnownMarketplaces`. The status line needs the `caveman` plugin.
- Credentials, history, sessions, projects, and cache.
