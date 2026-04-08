---
name: review-pr
description: "Post a staff-engineer-level code review with inline comments directly on a GitHub PR. Requires a PR URL or number as argument. Use when the user provides a GitHub PR link, says '/review-pr <number>', or asks to review a remote/existing PR on GitHub. Do NOT use for reviewing local uncommitted changes (that is ce-review)."
metadata:
  author: adryanev
  version: "1.0.0"
  argument-hint: "<pr-url-or-number>"
---

# Staff Engineer PR Review

Perform a thorough code review on a GitHub pull request and post inline comments directly on the PR.

## Input

The user provides a PR URL or number as the argument. Examples:

- `https://github.com/owner/repo/pulls/123`
- `owner/repo#123`
- `123` (uses the current repo)

Parse the argument to extract the `owner/repo` and PR number. If only a number is given, use the current git repo's remote.

## Step 1: Gather PR Context

Run these in parallel:

```bash
# Get PR metadata
gh pr view <number> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,state

# Get the full diff
gh pr diff <number> --repo <owner/repo>

# Get the head commit SHA (needed for posting review)
gh pr view <number> --repo <owner/repo> --json headRefOid --jq '.headRefOid'
```

## Step 2: Understand the Codebase (if needed)

If the PR touches patterns or conventions you are not sure about, use subagents to explore the codebase for relevant patterns. Focus on:

- Whether new code follows existing conventions
- Whether the project has documented architectural guidelines (CONTRIBUTING.md, CLAUDE.md, etc.)
- How similar features are implemented elsewhere in the codebase

## Step 3: Analyze the Diff

Review the diff as a staff software engineer. Evaluate:

1. **Correctness** - Logic errors, edge cases, off-by-one errors, race conditions
2. **Architecture** - Does this follow project conventions? Is the code in the right place?
3. **Security** - Input validation, injection risks, auth checks, secret exposure
4. **Performance** - N+1 queries, unnecessary allocations, missing indexes
5. **API design** - Consistency, backwards compatibility, proper status codes
6. **Test coverage** - Are critical paths tested? Are tests resilient to refactors?
7. **Readability** - Naming, complexity, unnecessary cleverness

## Step 4: Calculate Correct Line Numbers

**This is critical.** The GitHub API requires exact line numbers from the NEW version of the file.

For each comment, you MUST calculate the line number from the diff hunk headers:

- Diff hunk format: `@@ -old_start,old_count +new_start,new_count @@`
- For **new files** (`--- /dev/null`): line numbers start at 1 and go sequentially
- For **modified files**: count from `new_start` in the hunk header, tracking both context lines (no prefix) and added lines (`+` prefix). Skip removed lines (`-` prefix) as they don't exist in the new file
- Only comment on lines that are within a diff hunk. Lines outside hunks will cause API errors
- Always use `"side": "RIGHT"` for comments on new/modified lines

### Example Calculation

```
@@ -95,6 +96,20 @@
 context line          <- new file line 96
 context line          <- new file line 97
 context line          <- new file line 98
+added line            <- new file line 99  (commentable)
+added line            <- new file line 100 (commentable)
```

## Step 5: Post the Review

Use the GitHub API to post a single review with all inline comments:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input - <<'EOF'
{
  "commit_id": "<head_commit_sha>",
  "body": "<review summary>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.py",
      "side": "RIGHT",
      "line": <line_number_in_new_file>,
      "body": "<comment text>"
    }
  ]
}
EOF
```

## Review Style Guide

Follow these rules for tone and formatting:

### Tone
- Write as a **polite, direct staff engineer**. Not robotic, not snarky, not gushing.
- Be matter-of-fact. Don't over-praise. A brief "nice" or "solid" is fine, but don't dedicate full comments to complimenting code. If something is done well, note it in passing within a substantive comment, not as a standalone praise comment.
- Frame suggestions as improvements, not demands. Use "consider", "I'd suggest", "one option is".
- When pointing out issues, explain **why** it matters, not just what's wrong.
- Never use emdash characters. Use commas, periods, or "and" instead.

### Review Body Structure

Start with:
1. A one-line acknowledgment of the PR's purpose (not effusive)
2. The main architectural or structural concern (if any)
3. A concise summary of inline comments grouped by theme (backend, frontend, tests, etc.)

Do NOT include a "what's working well" section. If something is notably well done, mention it briefly in the summary or in an inline comment where it's contextually relevant.

### Inline Comments
- Include **code suggestions** with fenced code blocks when proposing alternatives
- For non-blocking suggestions, say "Not a blocker" or "Minor suggestion"
- For patterns that repeat, comment on the first occurrence and say "This pattern appears in X other places"
- Do NOT write standalone praise-only comments. Every comment should contain actionable information, a question, or a non-obvious observation. If you want to acknowledge good work, fold it into a comment that also says something substantive (e.g., "This handles the race condition correctly. One edge case to consider: ...")
- Aim for a high signal-to-noise ratio. Fewer, meatier comments beat many shallow ones.

### Things to Watch For
- New pages/features using legacy patterns when modern alternatives exist
- Hardcoded values that should use configuration or theme variables
- Broad exception handling (`except Exception`) that swallows real errors
- Props/state anti-patterns (duplicating props into state, mutating props)
- API inconsistencies (mixed conventions between similar endpoints)
- Hardcoded URLs in tests instead of `reverse()` or named routes
- Deprecated APIs for the framework version in use
- Missing input validation at system boundaries

### What NOT to Do
- Don't mention CLAUDE.md or any AI-specific configuration files
- Don't add co-author trailers or AI attribution
- Don't be pedantic about style issues that a linter would catch
- Don't suggest changes that would expand scope beyond the PR's purpose
- Don't comment on every file just to show thoroughness. Only comment where it matters.

## Error Handling

If the review API returns `422` with "Line could not be resolved":
1. The line numbers are wrong. Recalculate from the diff hunk headers.
2. Verify the line is within a diff hunk (not outside any `@@` range).
3. For modified files, verify the line exists in the NEW version (right side).
4. Retry with corrected line numbers.
