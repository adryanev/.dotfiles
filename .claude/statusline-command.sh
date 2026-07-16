#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code status line - insightful at a glance

input=$(cat)

# ── ANSI color helpers (will render dimmed in Claude Code's status area) ──────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

C_CYAN='\033[36m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_BLUE='\033[34m'
C_MAGENTA='\033[35m'
C_WHITE='\033[37m'
C_GRAY='\033[90m'

SEP="${C_GRAY} │ ${RESET}"

# ── Parse JSON input ──────────────────────────────────────────────────────────
cwd=$(echo "$input"           | jq -r '.cwd // .workspace.current_dir // ""')
project_dir=$(echo "$input"   | jq -r '.workspace.project_dir // ""')
model=$(echo "$input"         | jq -r '.model.display_name // ""')
session_name=$(echo "$input"  | jq -r '.session_name // ""')
used_pct=$(echo "$input"      | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
# total_input_tokens covers the full context window (cache reads + writes + fresh input)
ctx_input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
ctx_window_size=$(echo "$input"  | jq -r '.context_window.context_window_size // empty')
vim_mode=$(echo "$input"      | jq -r '.vim.mode // ""')
output_style=$(echo "$input"  | jq -r '.output_style.name // ""')

# ── 1. DIRECTORY (relative to project root when possible) ─────────────────────
if [[ -n "$project_dir" && "$cwd" == "$project_dir"* ]]; then
  rel="${cwd#$project_dir}"
  rel="${rel#/}"
  [[ -z "$rel" ]] && rel="."
  dir_str="${C_CYAN}$(basename "$project_dir")${C_GRAY}/${C_WHITE}${rel}${RESET}"
else
  dir_str="${C_CYAN}$(basename "$cwd")${RESET}"
fi

# ── 2. GIT INSIGHTS ───────────────────────────────────────────────────────────
git_str=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  # Ahead / behind upstream
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
  ahead=0; behind=0
  if [[ -n "$upstream" ]]; then
    ahead=$(git -C "$cwd" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
  fi

  # Working tree summary
  staged=$(git -C "$cwd" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  unstaged=$(git -C "$cwd" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  branch_color=$C_GREEN
  [[ "$branch" == "main" || "$branch" == "master" ]] && branch_color=$C_YELLOW

  git_str="${branch_color}${branch}${RESET}"

  # Upstream delta badges
  sync_info=""
  [[ "$ahead" -gt 0 ]]  && sync_info+="${C_GREEN}↑${ahead}${RESET}"
  [[ "$behind" -gt 0 ]] && sync_info+="${C_RED}↓${behind}${RESET}"
  [[ -n "$sync_info" ]]  && git_str+=" ${sync_info}"

  # Dirty state badges
  dirty=""
  [[ "$staged"    -gt 0 ]] && dirty+="${C_GREEN}+${staged}${RESET}"
  [[ "$unstaged"  -gt 0 ]] && dirty+="${C_YELLOW}~${unstaged}${RESET}"
  [[ "$untracked" -gt 0 ]] && dirty+="${C_GRAY}?${untracked}${RESET}"
  [[ -n "$dirty" ]] && git_str+=" ${dirty}"

fi

# ── 3. CONTEXT WINDOW PROGRESS BAR ───────────────────────────────────────────
ctx_str=""
if [[ -n "$used_pct" ]]; then
  # Round to integer
  pct=$(printf "%.0f" "$used_pct")
  bar_width=12
  filled=$(( pct * bar_width / 100 ))
  empty=$(( bar_width - filled ))

  # Color: green → yellow → red
  if   [[ "$pct" -lt 50 ]]; then bar_color=$C_GREEN
  elif [[ "$pct" -lt 80 ]]; then bar_color=$C_YELLOW
  else                            bar_color=$C_RED
  fi

  bar="${bar_color}"
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  bar+="${C_GRAY}"
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  bar+="${RESET}"

  ctx_str="${C_GRAY}ctx${RESET} ${bar} ${bar_color}${pct}%${RESET}"
fi

# ── 3b. TOKEN USAGE (current context vs window size) ─────────────────────────
tok_str=""
if [[ -n "$ctx_input_tokens" && -n "$ctx_window_size" ]]; then
  # Format a raw token count as a human-readable string: "127.3k" or "850"
  _fmt_tokens() {
    local n=$1
    if [[ "$n" -ge 1000 ]]; then
      # One decimal place in thousands
      printf "%.1fk" "$(echo "scale=4; $n / 1000" | bc)"
    else
      printf "%d" "$n"
    fi
  }

  used_fmt=$(_fmt_tokens "$ctx_input_tokens")
  win_fmt=$(_fmt_tokens "$ctx_window_size")

  # Reuse the same colour as the progress bar (green/yellow/red)
  if [[ -n "$used_pct" ]]; then
    pct_for_tok=$(printf "%.0f" "$used_pct")
    if   [[ "$pct_for_tok" -lt 50 ]]; then tok_color=$C_GREEN
    elif [[ "$pct_for_tok" -lt 80 ]]; then tok_color=$C_YELLOW
    else                                    tok_color=$C_RED
    fi
  else
    tok_color=$C_WHITE
  fi

  tok_str="${C_GRAY}tok${RESET} ${tok_color}${used_fmt}${C_GRAY}/${RESET}${C_WHITE}${win_fmt}${RESET}"
fi


# ── 4. MODEL ─────────────────────────────────────────────────────────────────
model_str=""
if [[ -n "$model" ]]; then
  model_str="${C_MAGENTA}${model}${RESET}"
fi

# ── 5. SESSION NAME ───────────────────────────────────────────────────────────
session_str=""
if [[ -n "$session_name" ]]; then
  session_str="${C_BLUE}${session_name}${RESET}"
fi

# ── 6. VIM MODE ───────────────────────────────────────────────────────────────
vim_str=""
if [[ -n "$vim_mode" ]]; then
  if [[ "$vim_mode" == "NORMAL" ]]; then
    vim_str="${C_YELLOW}[N]${RESET}"
  else
    vim_str="${C_GREEN}[I]${RESET}"
  fi
fi

# ── 7. OUTPUT STYLE (non-default) ─────────────────────────────────────────────
style_str=""
if [[ -n "$output_style" && "$output_style" != "default" ]]; then
  style_str="${C_GRAY}style:${C_WHITE}${output_style}${RESET}"
fi

# ── Assemble the line ──────────────────────────────────────────────────────────
parts=()

[[ -n "$vim_str"     ]] && parts+=("$vim_str")
[[ -n "$dir_str"     ]] && parts+=("$dir_str")
[[ -n "$git_str"     ]] && parts+=("$git_str")
[[ -n "$ctx_str"     ]] && parts+=("$ctx_str")
[[ -n "$tok_str"     ]] && parts+=("$tok_str")
[[ -n "$model_str"   ]] && parts+=("$model_str")
[[ -n "$session_str" ]] && parts+=("$session_str")
[[ -n "$style_str"   ]] && parts+=("$style_str")

line=""
for (( i=0; i<${#parts[@]}; i++ )); do
  [[ $i -gt 0 ]] && line+="$(printf "$SEP")"
  line+="${parts[$i]}"
done

printf "%b\n" "$line"
