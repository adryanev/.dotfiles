#!/usr/bin/env bash
# Airflow REST API v2 helper script
# Usage: airflow_api.sh <command> [args...]
#
# Environment variables (required):
#   AIRFLOW_BASE_URL  - e.g., http://localhost:8080
#   AIRFLOW_USERNAME  - e.g., admin
#   AIRFLOW_PASSWORD  - e.g., admin
#
# Commands:
#   health                          - Check Airflow health
#   token                           - Get JWT token (prints token only)
#   dags                            - List all DAGs
#   dag <dag_id>                    - Get DAG details
#   trigger <dag_id> [conf_json]    - Trigger a DAG run
#   runs <dag_id> [limit]           - List recent DAG runs
#   run <dag_id> <run_id>           - Get DAG run details
#   tasks <dag_id> <run_id>         - List task instances
#   task <dag_id> <run_id> <task>   - Get task instance details
#   logs <dag_id> <run_id> <task> [try] - Get task logs
#   poll <dag_id> <run_id> [interval]   - Poll run until terminal state
#   import-errors                   - List DAG import errors
#   unpause <dag_id>                - Unpause a DAG
#   pause <dag_id>                  - Pause a DAG

set -euo pipefail

: "${AIRFLOW_BASE_URL:?Set AIRFLOW_BASE_URL (e.g., http://localhost:8080)}"
: "${AIRFLOW_USERNAME:?Set AIRFLOW_USERNAME}"
: "${AIRFLOW_PASSWORD:?Set AIRFLOW_PASSWORD}"

API="$AIRFLOW_BASE_URL/api/v2"

# ── Token management ──────────────────────────────────────────────────

get_token() {
  local resp
  resp=$(curl -sf -X POST "$AIRFLOW_BASE_URL/auth/token" \
    -H "Content-Type: application/json" \
    -d '{"username": "'"$AIRFLOW_USERNAME"'", "password": "'"$AIRFLOW_PASSWORD"'"}' 2>/dev/null)

  if [ $? -ne 0 ] || [ -z "$resp" ]; then
    # Fallback: try basic auth (some Airflow configs support it directly)
    echo "__BASIC_AUTH__"
    return
  fi

  echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || echo "__BASIC_AUTH__"
}

TOKEN=$(get_token)

api_call() {
  local method="$1" path="$2"
  shift 2

  if [ "$TOKEN" = "__BASIC_AUTH__" ]; then
    curl -sf -u "$AIRFLOW_USERNAME:$AIRFLOW_PASSWORD" \
      -X "$method" "$API$path" \
      -H "Content-Type: application/json" "$@"
  else
    curl -sf -X "$method" "$API$path" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" "$@"
  fi
}

# ── Commands ──────────────────────────────────────────────────────────

cmd_health() {
  curl -sf "$API/monitor/health" | python3 -m json.tool
}

cmd_token() {
  if [ "$TOKEN" = "__BASIC_AUTH__" ]; then
    echo "(using basic auth fallback)"
  else
    echo "$TOKEN"
  fi
}

cmd_dags() {
  api_call GET "/dags?limit=100&only_active=true" | python3 -m json.tool
}

cmd_dag() {
  local dag_id="$1"
  api_call GET "/dags/$dag_id" | python3 -m json.tool
}

cmd_trigger() {
  local dag_id="$1"
  local conf="${2:-}"
  local logical_date
  logical_date=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).isoformat())")

  local body
  if [ -n "$conf" ]; then
    body=$(python3 -c "
import json
conf = json.loads('''$conf''')
print(json.dumps({'logical_date': '$logical_date', 'conf': conf, 'note': 'Triggered via Claude'}))
")
  else
    body="{\"logical_date\": \"$logical_date\", \"note\": \"Triggered via Claude\"}"
  fi

  api_call POST "/dags/$dag_id/dagRuns" -d "$body" | python3 -m json.tool
}

cmd_runs() {
  local dag_id="$1"
  local limit="${2:-5}"
  api_call GET "/dags/$dag_id/dagRuns?limit=$limit&order_by=-start_date" | python3 -m json.tool
}

cmd_run() {
  local dag_id="$1" run_id="$2"
  api_call GET "/dags/$dag_id/dagRuns/$run_id" | python3 -m json.tool
}

cmd_tasks() {
  local dag_id="$1" run_id="$2"
  api_call GET "/dags/$dag_id/dagRuns/$run_id/taskInstances" | python3 -m json.tool
}

cmd_task() {
  local dag_id="$1" run_id="$2" task_id="$3"
  api_call GET "/dags/$dag_id/dagRuns/$run_id/taskInstances/$task_id" | python3 -m json.tool
}

cmd_logs() {
  local dag_id="$1" run_id="$2" task_id="$3" try="${4:-1}"
  api_call GET "/dags/$dag_id/dagRuns/$run_id/taskInstances/$task_id/logs/$try?full_content=true"
}

cmd_poll() {
  local dag_id="$1" run_id="$2" interval="${3:-10}"
  echo "Polling $dag_id / $run_id every ${interval}s..."
  while true; do
    local resp
    resp=$(api_call GET "/dags/$dag_id/dagRuns/$run_id")
    local state
    state=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('state','unknown'))")
    local now
    now=$(date +%H:%M:%S)
    echo "[$now] State: $state"

    case "$state" in
      success|failed) echo "$resp" | python3 -m json.tool; break ;;
      *) sleep "$interval" ;;
    esac
  done
}

cmd_import_errors() {
  api_call GET "/importErrors" | python3 -m json.tool
}

cmd_unpause() {
  local dag_id="$1"
  api_call PATCH "/dags/$dag_id" -d '{"is_paused": false}' | python3 -m json.tool
}

cmd_pause() {
  local dag_id="$1"
  api_call PATCH "/dags/$dag_id" -d '{"is_paused": true}' | python3 -m json.tool
}

# ── Dispatch ──────────────────────────────────────────────────────────

case "${1:-help}" in
  health)         cmd_health ;;
  token)          cmd_token ;;
  dags)           cmd_dags ;;
  dag)            cmd_dag "${2:?dag_id required}" ;;
  trigger)        cmd_trigger "${2:?dag_id required}" "${3:-}" ;;
  runs)           cmd_runs "${2:?dag_id required}" "${3:-5}" ;;
  run)            cmd_run "${2:?dag_id required}" "${3:?run_id required}" ;;
  tasks)          cmd_tasks "${2:?dag_id required}" "${3:?run_id required}" ;;
  task)           cmd_task "${2:?dag_id required}" "${3:?run_id required}" "${4:?task_id required}" ;;
  logs)           cmd_logs "${2:?dag_id required}" "${3:?run_id required}" "${4:?task_id required}" "${5:-1}" ;;
  poll)           cmd_poll "${2:?dag_id required}" "${3:?run_id required}" "${4:-10}" ;;
  import-errors)  cmd_import_errors ;;
  unpause)        cmd_unpause "${2:?dag_id required}" ;;
  pause)          cmd_pause "${2:?dag_id required}" ;;
  help|*)
    sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
    ;;
esac
