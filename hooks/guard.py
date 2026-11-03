#!/usr/bin/env python3
# PreToolUse guard: hard stop for a few destructive actions, even in auto mode.
# Exit 2 blocks the tool call and shows stderr to Claude.
import json, os, re, sys

BASH_RULES = [
    (r"\brm\s+(-\w*r\w*f\w*|-\w*f\w*r\w*|-r\s+-f|-f\s+-r)\s+(/|~|\$HOME|\.|\.\.|\*)/?(\s|$|;|&|\|)",
     "rm -rf on /, ~, $HOME, ., .. or *"),
    (r"\bgit\s+push\b.*(\s--force(?!-with-lease)\b|\s-f\b)", "git push --force (use --force-with-lease)"),
    (r"\b(curl|wget)\b[^|;&]*\|\s*(sudo\s+)?(ba|z)?sh\b", "piping a download into a shell"),
]
SECRET_PATH = re.compile(r"(^|/)\.env(\.(?!example$|sample$|template$)[^/]+)?$|/\.ssh/|/\.aws/|/\.gnupg/")

data = json.load(sys.stdin)
tool, inp = data.get("tool_name", ""), data.get("tool_input", {})

if tool == "Bash":
    cmd = inp.get("command", "")
    for pattern, why in BASH_RULES:
        if re.search(pattern, cmd):
            sys.exit(print(f"Blocked by guard hook: {why}. Ask the user to run it.", file=sys.stderr) or 2)
elif tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
    path = os.path.expanduser(inp.get("file_path") or inp.get("notebook_path") or "")
    if SECRET_PATH.search(path):
        sys.exit(print(f"Blocked by guard hook: edit to secret file {path}. Ask the user.", file=sys.stderr) or 2)
