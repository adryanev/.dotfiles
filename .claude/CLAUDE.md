# Hard Rules

## Language and tone
Write in plain, formal, straightforward English. Do not use startup or Bay Area jargon. Do not use hype or edgy phrasing. Do not use idioms. Banned words and phrases include: "ship", "burn", "headline result", "de-risk", "blast radius", "lever", "anchor", "wiring", "punt", "land", "budget it", "stand up", "spin up", "low-key", "honestly", "vibe", "huge win", "massive", "tee up", "lock in". The user is not a native English speaker and finds this style difficult to read.

Use neutral technical English: state what something is, what it does, and what the numbers are. Prefer short declarative sentences. This rule applies to chat replies, commit messages, PR descriptions, and any other text the user reads.

---

# MCP & Tool Preferences

## rtk (token-optimized CLI proxy)
Prefix shell commands with `rtk` (e.g. `rtk git status`, `rtk npm install`). Saves 60-90% tokens.
Meta (use bare): `rtk gain` · `rtk discover` · `rtk proxy <cmd>`. See @RTK.md.

## codebase-memory-mcp (code graph)
For **code exploration**, prefer graph tools over Grep/Read:
- `search_graph` · `trace_path` · `get_code_snippet` · `query_graph` · `get_architecture`
- If not indexed: call `index_repository` first.
- Project name is injected at session start — use it as `project=` on every call.
- Fall back to Grep/Read only for text content, configs, non-code files.

## serena (symbolic navigation)
For **symbol-aware reading/editing**, prefer serena over reading whole files:
- Discover: `get_symbols_overview` · `find_symbol` (pass `include_body=False` until needed) · `find_referencing_symbols`
- Edit: `replace_symbol_body` · `insert_after_symbol` · `rename_symbol`
- Scope searches with `search_for_pattern` + `relative_path`.
- On new projects, check `check_onboarding_performed` and run `onboarding` if missing.

## Tool-selection order for code work
1. `codebase-memory-mcp` → find symbols and call graphs
2. `serena` → read/edit specific symbol bodies
3. `Grep`/`Read`/`Edit` → only when the above don't fit
