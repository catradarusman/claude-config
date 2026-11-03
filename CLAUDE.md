# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Read existing files before writing. Don't re-read unless changed. Skip files over 100KB unless required.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Gut check: would a senior engineer call this overcomplicated?

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken. Match existing style.
- Prefer editing over rewriting whole files.
- Unrelated dead code: mention it, don't delete it.
- Orphans your own change created: remove them.
- Every changed line should trace directly to the request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

- "Port module X" -> "run the same input through both implementations, diff the output byte-for-byte"
- "Fix the bug" -> "write a test that reproduces it, then make it pass"
- "Refactor" -> "tests pass before and after"
- For multi-step work, state the plan first: `[step] -> verify: [check]`
- Test before declaring done.

## 5. Token Economy

Context is the scarce resource. Spend it capped, deliberate, never drained on one call.

- Delete over add. Fewer lines = fewer tokens to re-read forever. Prune before extending.
- Don't re-derive what's already known - this file, a prior read, a test result. Re-reading unchanged files is the #1 silent token burn.
- Small tight diffs over big rewrites. A 200-line rewrite costs the reviewer a full re-read; a 10-line diff doesn't.
- Batch independent reads and greps into one turn instead of serial round-trips.
- Route narrow bounded subtasks (locate code, review a diff, single-file edit) to a scoped subagent. Keep main context for synthesis, not legwork.
- Verify by running the command, not by reasoning longer about what it probably does. A test run is cheaper than a paragraph of speculation, and it's actually true.
- No speculative abstraction, config, or error handling for cases that can't happen here. Every hypothetical branch is tokens spent now and re-read forever after.

## 6. Skills

Invoke via `Skill(...)`. Don't reinvent what these already cover.

| Skill | When |
|---|---|
| `anthropic-skills:systematic-debugging` | Any bug hunt - root cause before fix, no speculative patching |
| `engineering:code-review` | PR/diff review for correctness, perf, injection risk, invariant violations |
| `engineering:testing-strategy` | Designing test plans, coverage gaps, edge-case enumeration before writing tests |
| `security-review` | Before merging anything touching auth, permissions, payments, secrets, or user data |
| `gstack` | Structured plan/review/QA/ship for larger changes. `/qa` for live end-to-end, `/review` pre-landing |

## 7. gstack

`/gstack` is the router - invoke it when you know the job but not the command. `Skill(gstack)` works from any project.

**Browsing:** read a page with WebFetch or the built-in browser (`mcp__Claude_Browser__*`, prefer `get_page_text` over screenshots). Use `/browse` inside gstack flows (`/qa`, `/design-review`) or where no built-in browser exists (terminal CLI). Never use `mcp__claude-in-chrome__*` unless I ask.

| Stage | Commands |
|---|---|
| Shape | `/office-hours` `/spec` `/design-consultation` `/design-shotgun` |
| Plan review | `/plan-ceo-review` `/plan-eng-review` `/plan-design-review` `/plan-devex-review` `/autoplan` |
| Build | `/careful` `/codex` `/pair-agent` `/investigate` `/design-html` `/diagram` |
| Review | `/review` `/design-review` `/devex-review` `/cso` `/benchmark` `/benchmark-models` |
| QA | `/qa` `/qa-only` |
| Ship | `/ship` `/land-and-deploy` `/canary` `/document-release` `/document-generate` `/retro` |
| Context | `/context-save` `/context-restore` `/setup-gbrain` `/sync-gbrain` `/learn` `/plan-tune` |
| Rails | `/freeze` `/unfreeze` `/guard` |
| Web + tools | `/browse` `/open-gstack-browser` `/scrape` `/setup-browser-cookies` `/setup-deploy` `/make-pdf` `/landing-report` |
| iOS | `/ios-qa` `/ios-fix` `/ios-clean` `/ios-sync` `/ios-design-review` |
| Meta | `/health` `/skillify` `/gstack-upgrade` |

Gotcha: the browser command is `/open-gstack-browser`, not `/connect-chrome`. The directory is named `connect-chrome` but its frontmatter declares the other name, so `/connect-chrome` does not resolve.

If a command here fails to resolve, run `/health` - the roster moves between gstack releases and this table can go stale.

## 8. ethskills

Ethereum domain knowledge. Skip entirely on non-EVM work.

`ethskills:ship` is the router - it routes you through the rest. Start there on any new dApp.

| Area | Skills |
|---|---|
| Orientation | `ethskills:ship` `ethskills:why-ethereum` `ethskills:concepts` |
| Protocol | `ethskills:protocol` `ethskills:standards` `ethskills:gas` `ethskills:addresses` |
| Contracts | `ethskills:security` `ethskills:testing` `ethskills:audit` `ethskills:noir` |
| Frontend | `ethskills:frontend-ux` `ethskills:frontend-playbook` `ethskills:wallets` `ethskills:qa` |
| Infra | `ethskills:l2s` `ethskills:indexing` `ethskills:orchestration` `ethskills:tools` `ethskills:building-blocks` `ethskills:crops` |

`ethskills:frontend-ux` is the one to reach for by default on dApp UI - it carries the mandatory patterns for onchain buttons, approval flows, and RPC reliability.

Note: `ethskills:l2`, `:layer2`, `:contracts`, `:defi` are deprecated redirect stubs and are disabled. Use `:l2s`, `:addresses`, and `:building-blocks` instead.

## 9. Pre-merge gate

Mandatory before any merge to a default branch. No exceptions for "small" diffs.

1. **Security audit** - `Skill(security-review)` on the branch diff. Required for anything touching auth, permissions, payments, ownership, secrets, user data, or on-chain state. Report findings, don't silently pass.
2. **Code review** - `Skill(engineering:code-review)` on the full diff. Correctness, perf, injection, error paths, and any invariant the project CLAUDE.md declares.
3. **Test plan then execution** - `Skill(engineering:testing-strategy)` to enumerate cases and find coverage gaps. Then `/qa` for live end-to-end where a running UI exists. Say so explicitly when there isn't one yet.
4. **Suite green** - run the project's test command and paste the output. Never assert a pass from memory.

State the results of all four. If a step is skipped, name which and why.

The project CLAUDE.md supplies the specifics: the exact test command, and the invariants step 3 has to cover. This file supplies the discipline; it does not know your invariants.

**Merge on command.** When the user says "merge", run `gh pr merge <n> --merge` yourself. Do not hand the command to the user. The word "merge" is the approval for that PR only. Then verify with `gh pr view <n> --json state` and pull the default branch. If the merge is denied or fails, show the exact error.

Scale to the stakes. A change that can lose money, leak data, or cannot be rolled back gets all four with no shortcuts. A typo fix in a README does not.

## 10. Output

- Concise output, thorough reasoning. No sycophantic openers or closing fluff, no emojis, no em-dashes.
- Don't guess APIs, versions, flags, commit SHAs, or package names. Verify by reading code or docs first.

## 11. Session Hygiene

- Suggest `/cost` when a session runs long (cache ratio check).
- Recommend a new session when switching to an unrelated task.

## Writing Standard

**Chat replies:** caveman mode when active. Cheapest output.

**Files and text others read** (docs, READMEs, PR bodies, specs, UI copy): Simplified Technical English (ASD-STE100) plus Zinsser.

- One instruction per sentence. Max 20 words. Active voice.
- One word, one meaning. Cut clutter.
- Plain, brief, clear, warm. A person wrote this, not a manual.

Public posts in my voice: use `anthropic-skills:catra-voice` instead.

User instructions always override this file.
