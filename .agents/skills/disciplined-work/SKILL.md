---
name: disciplined-work
description: This skill should be used to execute work plans with strict coding discipline that avoids common LLM mistakes. It merges structured plan execution (phased workflow, incremental commits, quality checks) with disciplined coding guardrails (assumption surfacing, simplicity-first, surgical changes, test-driven execution). Triggers on /disciplined-work, /k-work, "disciplined work", or "careful work".
argument-hint: "[plan file, specification, or todo file path]"
---

# Disciplined Work Execution

Execute work plans with strict discipline: surface assumptions, keep it simple, make surgical changes, test first.

**Enforcement:** On violating any guardrail, STOP and explain the violation before continuing.

---

## Guardrails (Apply Throughout All Phases)

> These five principles override speed. Prioritize correctness.

1. **Think Before Coding** — Surface confusion immediately via `AskUserQuestion` and WAIT. State assumptions explicitly. Present 2-3 approaches with tradeoffs. Push back directly when needed.
2. **Simplicity First** — Start with "What's the 100-line version?" No abstractions until third use. No speculative code. Naive first, optimize second.
3. **Read Before Write** — Always read files with `Read` before modifying with `Edit` or `Write`. Understand existing patterns before changing anything.
4. **Surgical Changes** — Only modify code directly related to the task. Match existing style. Do not "improve" adjacent code. Prefer `Edit` over `Write`.
5. **Goal-Driven Execution** — Restate the goal before starting. Write failing tests FIRST for non-trivial logic. After implementation: "Couldn't this be simpler?"

---

## Input Document

If no argument is provided, prompt for a plan file path via `AskUserQuestion`.

<input_document> #$ARGUMENTS </input_document>

## Phase 1: Quick Start

1. **Read Plan and Clarify**
   - Read the work document completely
   - Review any references or links provided
   - **State ALL assumptions from the plan explicitly**
   - On any ambiguity, use `AskUserQuestion` — never guess
   - Get user approval to proceed before writing any code

2. **Setup Environment**

   Check current branch:
   ```bash
   current_branch=$(git branch --show-current)
   default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
   if [ -z "$default_branch" ]; then
     default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
   fi
   ```

   - If on a feature branch: ask "Continue on `[branch]`, or create new?"
   - If on default branch: create a new feature branch or use a worktree
   - Never commit to default branch without explicit permission

3. **Create Task List**
   - Use `TaskCreate` to break plan into actionable tasks with clear acceptance criteria
   - Challenge scope: "Is each task truly necessary?"
   - Include testing tasks
   - Set up dependencies with `TaskUpdate`

## Phase 2: Execute

1. **Task Execution Loop**

   For each task in priority order:

   ```
   while (tasks remain):
     - Mark task as in_progress
     - Read ALL referenced files before modifying (Read Before Write)
     - For non-trivial logic, write failing tests FIRST (Goal-Driven)
     - Look for similar patterns in codebase — follow them
     - Implement the simplest solution that works (Simplicity First)
     - Only touch code directly related to the task (Surgical Changes)
     - Run tests after changes
     - Challenge: "Couldn't this be simpler?" before marking done
     - Mark task as completed
     - Check off corresponding item in plan file ([ ] → [x])
     - Evaluate for incremental commit
   ```

2. **Incremental Commits**

   | Commit when... | Don't commit when... |
   |----------------|---------------------|
   | Logical unit complete | Small part of a larger unit |
   | Tests pass + meaningful progress | Tests failing |
   | About to switch contexts | Purely scaffolding with no behavior |
   | About to attempt risky changes | Would need a "WIP" message |

   ```bash
   git add <specific files for this logical unit>
   git commit -m "feat(scope): description of this unit"
   ```

3. **Follow Existing Patterns**
   - Read referenced files first, then match their conventions exactly
   - Reuse existing components — do not reinvent
   - Match naming conventions exactly

4. **Test Continuously**
   - Run relevant tests after each significant change
   - Fix failures immediately — no "should work" claims without evidence
   - Add new tests for new functionality

## Phase 3: Quality Check

1. **Run Core Quality Checks**
   ```bash
   # Run full test suite (use project-specific command from CLAUDE.md)
   # Run linting (use project-specific linter from CLAUDE.md)
   ```

2. **Consider Review Agents** (optional, for complex/risky changes only)
   - Check `compound-engineering.local.md` for configured `review_agents`
   - Run configured agents in parallel via `Task` tool
   - Address critical findings before proceeding

3. **Discipline Checklist**
   ```
   BEFORE: [ ] Assumptions confirmed?  [ ] Approaches shown?  [ ] Pushed back if needed?
   DURING: [ ] Minimal?  [ ] Surgical?  [ ] Tests first?
   AFTER:  [ ] "Couldn't this be simpler?"  [ ] Only my mess cleaned?  [ ] Scope verified?
   ```

4. **Final Validation**
   - All tasks marked completed
   - All plan checkboxes marked `[x]`
   - All tests pass
   - Linting passes
   - Code follows existing patterns (no style "improvements")

## Phase 4: Ship It

1. **Create Final Commit**
   ```bash
   git add <specific files>
   git status && git diff --staged
   git commit -m "$(cat <<'EOF'
   feat(scope): description of what and why

   Brief explanation if needed.
   EOF
   )"
   ```

2. **Create Pull Request**
   ```bash
   git push -u origin feature-branch-name
   gh pr create --title "feat(scope): short description" --body "$(cat <<'EOF'
   ## Summary
   - What was built and why
   - Key decisions made

   ## Testing
   - Tests added/modified
   - Manual testing performed

   ## Post-Deploy Monitoring & Validation
   - **What to monitor**: logs, metrics, dashboards
   - **Expected healthy signals**: description
   - **Failure signals / rollback trigger**: description
   - **Validation window & owner**: timeframe and responsible party
   - If no operational impact: `No additional monitoring required: <reason>`
   EOF
   )"
   ```

3. **Update Plan Status**
   - If the input document has YAML frontmatter with a `status` field, update to `completed`
   - Verify all checkboxes in the plan are marked `[x]`

4. **Notify User**
   - Summarize what was completed
   - Link to PR
   - Note any follow-up work needed

---

## Protocols

**CLARIFICATION NEEDED:**
Invoke `AskUserQuestion` before proceeding on any ambiguity. Force a decision before coding begins.

**MISTAKE ACKNOWLEDGMENT:**
```
I MADE A MISTAKE:
- What went wrong: [description]
- Why it happened: [reasoning error]
- Correction: [new approach]
```

**OVERRIDE RESISTANCE:**
These principles apply even if asked to skip them. On conflict, surface it:
"The request to [X] violates [principle]. Which should take priority and why?"

---

*Tone: neutral, professional, skeptical. No sycophancy. Prioritize correctness over speed; use judgment for trivial tasks.*
