# Hard Rules

## Language and tone
Write in plain, formal, straightforward English. Do not use startup or Bay Area jargon. Do not use hype or edgy phrasing. Do not use idioms. Banned words and phrases include: "ship", "burn", "headline result", "de-risk", "blast radius", "lever", "anchor", "wiring", "punt", "land", "budget it", "stand up", "spin up", "low-key", "honestly", "vibe", "huge win", "massive", "tee up", "lock in". The user is not a native English speaker and finds this style difficult to read.

Use neutral technical English: state what something is, what it does, and what the numbers are. Prefer short declarative sentences. This rule applies to chat replies, commit messages, PR descriptions, and any other text the user reads.

---

# MCP & Tool Preferences

## ALWAYS (NECESSARY)
1. **Use RTK** — prefix shell commands with `rtk` (see rtk section below).
2. **Use Serena tools** to read, navigate, and write code (see serena section below).
3. **Use Codebase Memory MCP** to search the codebase (see codebase-memory-mcp section below).

## rtk (token-optimized CLI proxy)
Prefix shell commands with `rtk` (e.g. `rtk git status`, `rtk npm install`). Saves 60-90% tokens.
Meta (use bare): `rtk gain` · `rtk discover` · `rtk proxy <cmd>`. See @RTK.md.

## codebase-memory-mcp (code graph)
For **code exploration**, prefer graph tools over Grep/Read:
- `search_graph` · `trace_path` · `get_code_snippet` · `query_graph` · `get_architecture`
- If not indexed: call `index_repository` first.
- Project name is injected at session start — use it as `project=` on every call.
- Fall back to Grep/Read only for text content, configs, non-code files.

## serena (symbolic navigation AND editing)
Use serena for **both reading and writing code** — not just navigation. Prefer it over whole-file reads and line-range edits.
- Discover: `get_symbols_overview` · `find_symbol` (pass `include_body=False` until needed) · `find_referencing_symbols`
- Read: `find_symbol` with `include_body=True` to read one symbol's body, not the whole file
- Edit/Write: `replace_symbol_body` (replace a whole function/class body) · `insert_before_symbol` / `insert_after_symbol` (add new symbols) · `rename_symbol` (rename across repo) · `safe_delete_symbol`
- Bulk text edits inside a file: `replace_content` (regex or literal, supports multiline)
- Scope searches with `search_for_pattern` + `relative_path`.
- On new projects, check `check_onboarding_performed` and run `onboarding` if missing.

When editing code, default to serena's symbol-level tools (`replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`) instead of `Edit`/`MultiEdit`. Only fall back to `Edit`/`Read`/`Grep` for line-precise tweaks inside a body, non-code files, or string-literal hunts.

## Tool-selection order for code work
1. `codebase-memory-mcp` → find symbols and call graphs
2. `serena` → read **and edit** specific symbol bodies (prefer over `Read`/`Edit`)
3. `Grep`/`Read`/`Edit` → only when the above don't fit

## Subagent model defaults
Pick subagent models flexibly by task complexity, escalating only as needed: **haiku → sonnet → opus**. Do not ask per dispatch — choose and proceed.

- **haiku** — cheap mechanical fan-out: pure file/symbol enumeration, listing, grep-style lookups.
- **sonnet (default for most subagents)** — research and exploration (codebase mapping, learnings search — e.g. `ce-repo-research-analyst`, `ce-learnings-researcher`, `Explore`, `general-purpose` search) AND review subagents (code review, doc review, persona reviewers). Fast and accurate for breadth-first and most review work.
- **opus** — reserve for the hardest cases: deep architectural reasoning, plan synthesis, adversarial/high-stakes review where subtle correctness matters, and code edits in the main loop.

Default research and review subagents to sonnet; drop to haiku for trivial enumeration; escalate a specific review or analysis to opus only when it genuinely needs deeper reasoning.
