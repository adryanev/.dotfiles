<!-- BEGIN COMPOUND CODEX TOOL MAP -->
## Compound Codex Tool Mapping (Claude Compatibility)

This section maps Claude Code plugin tool references to Codex behavior.
Only this block is managed automatically.

Tool mapping:
- Read: use shell reads (cat/sed) or rg
- Write: create files via shell redirection or apply_patch
- Edit/MultiEdit: use apply_patch
- Bash: use shell_command
- Grep: use rg (fallback: grep)
- Glob: use rg --files or find
- LS: use ls via shell_command
- WebFetch/WebSearch: use curl or Context7 for library docs
- AskUserQuestion/Question: present choices as a numbered list in chat and wait for a reply number. For multi-select (multiSelect: true), accept comma-separated numbers. Never skip or auto-configure — always wait for the user's response before proceeding.
- Task (subagent dispatch) / Subagent / Parallel: run sequentially in main thread; use multi_tool_use.parallel for tool calls
- TaskCreate/TaskUpdate/TaskList/TaskGet/TaskStop/TaskOutput (Claude Code task-tracking, current): use update_plan (Codex's task-tracking primitive)
- TodoWrite/TodoRead (Claude Code task-tracking, legacy — deprecated, replaced by Task* tools): use update_plan
- Skill: open the referenced SKILL.md and follow it
- ExitPlanMode: ignore
<!-- END COMPOUND CODEX TOOL MAP -->

@/Users/adryanev/.codex/RTK.md


<!-- headroom:rtk-instructions -->
# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with `rtk`**. This reduces context
usage by 60-90% with zero behavior change. If rtk has no filter for a command,
it passes through unchanged — so it is always safe to use.

## Key Commands
```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Infrastructure (85% savings)
rtk docker ps           rtk kubectl get         rtk docker logs <c>

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```

## Rules
- In command chains, prefix each segment: `rtk git add . && rtk git commit -m "msg"`
- For debugging, use raw command without rtk prefix
- `rtk proxy <cmd>` runs command without filtering but tracks usage
<!-- /headroom:rtk-instructions -->

<!-- codebase-memory-mcp:start -->
# Codebase Knowledge Graph (codebase-memory-mcp)

This project uses codebase-memory-mcp to maintain a knowledge graph of the codebase.
ALWAYS prefer MCP graph tools over grep/glob/file-search for code discovery.

## Priority Order
1. `search_graph` — find functions, classes, routes, variables by pattern
2. `trace_path` — trace who calls a function or what it calls
3. `get_code_snippet` — read specific function/class source code
4. `query_graph` — run Cypher queries for complex patterns
5. `get_architecture` — high-level project summary

## Project resolution
- In Git worktrees, use the codebase-memory project for the canonical checkout
  behind `git rev-parse --git-common-dir`, not the worktree path under
  `conductor/workspaces`.
- Example: `/Users/adryanev/conductor/workspaces/backend/*` should use
  `Users-adryanev-Code-lexicon-backend`.

## When to fall back to grep/glob
- Searching for string literals, error messages, config values
- Searching non-code files (Dockerfiles, shell scripts, configs)
- When MCP tools return insufficient results

## Examples
- Find a handler: `search_graph(name_pattern=".*OrderHandler.*")`
- Who calls it: `trace_path(function_name="OrderHandler", direction="inbound")`
- Read source: `get_code_snippet(qualified_name="pkg/orders.OrderHandler")`
<!-- codebase-memory-mcp:end -->

<!-- serena:start -->
# Symbolic Code Navigation AND Editing (serena MCP)

Use serena MCP tools for **both symbolic reading and writing code**. Prefer them
over cat/sed/rg/apply_patch when you need to understand or modify code by symbol
rather than by line range. Serena is not navigation-only — use it as the primary
editing surface for code.

## Priority Order
1. `mcp__serena__get_symbols_overview` — first look at a new file; lists top-level symbols.
2. `mcp__serena__find_symbol` — read a specific symbol. Use `include_body=true` for the body, `depth=1` to list children. Never read an entire file when you only need one symbol.
3. `mcp__serena__find_referencing_symbols` — find callers / usages.
4. `mcp__serena__search_for_pattern` — regex search restricted to code context.
5. **Editing (prefer over apply_patch for whole-symbol changes):**
   - `mcp__serena__replace_symbol_body` — replace a whole function/class body.
   - `mcp__serena__insert_before_symbol` / `mcp__serena__insert_after_symbol` — add new symbols.
   - `mcp__serena__rename_symbol` — rename across the repo.
   - `mcp__serena__safe_delete_symbol` — delete after confirming no references.
   - `mcp__serena__replace_content` — bulk regex/literal text edits inside a file (multiline supported).

## Editing policy
- For replacing a whole function, method, or class body: use `replace_symbol_body`, not `apply_patch`.
- For adding a new symbol (function, class, method, import): use `insert_before_symbol` / `insert_after_symbol`.
- For renaming across the codebase: use `rename_symbol`, not manual find-and-replace.
- For bulk text edits inside one file: use `replace_content` (regex or literal).
- Fall back to `apply_patch` only for: line-precise tweaks inside a body, non-code files, or string-literal hunts.

## When to fall back to shell reads
- Non-code files (markdown, JSON, YAML, shell scripts).
- String-literal hunts (error messages, env vars).
- Line-precise tweaks inside a function body (apply_patch is cleaner).

## Onboarding
If onboarding has not been performed on a new project and the task is code-heavy, call `mcp__serena__check_onboarding_performed` before the first symbolic query.
<!-- serena:end -->



