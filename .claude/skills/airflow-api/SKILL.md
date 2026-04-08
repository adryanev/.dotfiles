---
name: airflow-api
description: "This skill should be used when interacting with the Airflow REST API to trigger DAG runs, monitor execution, view task logs, and debug pipeline failures. Triggers on requests like run the DAG, trigger airflow, test the pipeline, check DAG status, show task logs, or any mention of testing, running, or monitoring Airflow DAGs."
---

# Airflow API

Interact with Apache Airflow 3.1 REST API v2 to trigger, monitor, and debug DAG runs.

## Prerequisites Check

**Before any API call, verify Airflow is running:**

```bash
curl -sf http://localhost:8080/api/v2/monitor/health > /dev/null 2>&1 && echo "OK" || echo "UNREACHABLE"
```

If unreachable, stop and tell the user:

> Airflow is not running at `http://localhost:8080`. Start it with your Docker Compose setup before proceeding.

Do not attempt any API calls until the health check passes.

## Environment Setup

Three environment variables are required. Check if they are set; if not, prompt the user or use defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `AIRFLOW_BASE_URL` | `http://localhost:8080` | Airflow webserver URL |
| `AIRFLOW_USERNAME` | `admin` | API username |
| `AIRFLOW_PASSWORD` | _(none)_ | API password — must be provided |

If `AIRFLOW_PASSWORD` is not set, ask the user for it before proceeding.

To set defaults when not configured:

```bash
export AIRFLOW_BASE_URL="${AIRFLOW_BASE_URL:-http://localhost:8080}"
export AIRFLOW_USERNAME="${AIRFLOW_USERNAME:-admin}"
```

## Helper Script

A shell script is bundled at `scripts/airflow_api.sh` for common operations. Execute directly via Bash:

```bash
bash scripts/airflow_api.sh <command> [args...]
```

Available commands: `health`, `dags`, `dag <id>`, `trigger <id> [conf]`, `runs <id>`, `run <id> <run_id>`, `tasks <id> <run_id>`, `task <id> <run_id> <task>`, `logs <id> <run_id> <task> [try]`, `poll <id> <run_id>`, `import-errors`, `unpause <id>`, `pause <id>`

The script handles JWT token acquisition automatically, with basic auth fallback.

## Core Workflows

### 1. Trigger and Monitor a DAG

The most common workflow: trigger a DAG run and monitor it to completion.

**Steps:**

1. **Health check** — Verify Airflow is running
2. **Check import errors** — Ensure DAG has no syntax errors
3. **Unpause DAG** — DAGs may be paused by default in production
4. **Trigger DAG run** — Start execution
5. **Poll for completion** — Wait for terminal state (success/failed)
6. **Inspect results** — Check task states and logs

```bash
# 1. Health check
bash scripts/airflow_api.sh health

# 2. Check for import errors
bash scripts/airflow_api.sh import-errors

# 3. Discover DAGs — find the right dag_id
bash scripts/airflow_api.sh dags

# 4. Unpause if needed
bash scripts/airflow_api.sh unpause <dag_id>

# 5. Trigger
bash scripts/airflow_api.sh trigger <dag_id>

# 6. Poll (extract dag_run_id from trigger response, poll every 15s)
bash scripts/airflow_api.sh poll <dag_id> <dag_run_id> 15

# 7. List task results
bash scripts/airflow_api.sh tasks <dag_id> <dag_run_id>
```

### 2. Debug a Failed DAG Run

When a run fails, inspect task instances and logs to find the root cause.

**Steps:**

1. **List recent runs** — Find the failed run
2. **List task instances** — Identify which task(s) failed
3. **Get task logs** — Read error messages and stack traces
4. **Optionally clear and retry** — Re-run specific failed tasks

```bash
# 1. Recent runs (last 5)
bash scripts/airflow_api.sh runs <dag_id>

# 2. Task instances for a specific run
bash scripts/airflow_api.sh tasks <dag_id> <dag_run_id>

# 3. Logs for failed task (try_number=1)
bash scripts/airflow_api.sh logs <dag_id> <dag_run_id> <task_id> 1
```

### 3. Check DAG Status

Quick status overview without triggering anything.

```bash
# List all active DAGs
bash scripts/airflow_api.sh dags

# Get specific DAG details (schedule, is_paused, etc.)
bash scripts/airflow_api.sh dag bpk_regulation_extraction

# Recent runs
bash scripts/airflow_api.sh runs bpk_regulation_extraction
```

### 4. Trigger with Custom Configuration

Pass runtime configuration to a DAG via the `conf` parameter.

```bash
bash scripts/airflow_api.sh trigger bpk_regulation_extraction '{"batch_size": 5}'
```

## Direct curl Usage

When the helper script does not cover a specific endpoint, use curl directly. Consult `references/api_reference.md` for the full endpoint reference.

**Authentication pattern:**

```bash
# Get token
TOKEN=$(curl -sf -X POST "$AIRFLOW_BASE_URL/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"username": "'"$AIRFLOW_USERNAME"'", "password": "'"$AIRFLOW_PASSWORD"'"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Use token
curl -sf -H "Authorization: Bearer $TOKEN" "$AIRFLOW_BASE_URL/api/v2/dags"
```

**Basic auth fallback** (if JWT endpoint is not available):

```bash
curl -sf -u "$AIRFLOW_USERNAME:$AIRFLOW_PASSWORD" "$AIRFLOW_BASE_URL/api/v2/dags"
```

## Discovering DAGs

Never assume DAG IDs. Always scan available DAGs first:

```bash
bash scripts/airflow_api.sh dags
```

Parse the response to find the relevant DAG by matching the user's intent to DAG IDs and tags.
If the user's request is ambiguous (e.g., "run the extraction pipeline"), list available DAGs and ask which one to trigger.

## Interpreting Results

### DAG Run States
- `queued` — Waiting for scheduler
- `running` — Currently executing
- `success` — All tasks completed successfully
- `failed` — At least one task failed

### Task Instance States
- `success` — Task completed
- `failed` — Task raised an exception (check logs)
- `upstream_failed` — Dependency task failed (check upstream)
- `up_for_retry` — Failed but will retry (check retries config)
- `running` — Currently executing
- `skipped` — Skipped by branching logic or trigger rules

### XCom Values

This project's DAGs return lightweight XCom dicts with: `source_id`, `status`, `error`, `counts`, `time_ms`. Never PII.

## Important Notes

- **Poll interval**: Use 10–15s for most DAGs. LLM extraction pipelines can take 30+ minutes per run.
- **Dynamic tasks**: DAGs using `.expand()` (dynamic task mapping) produce task instances named like `task_name__0`, `task_name__1`, etc. List task instances to discover actual names.
- **Paused DAGs**: Production DAGs may start paused. Always check and unpause before triggering.
- **Long-running tasks**: Some pipelines have per-task execution timeouts. Check DAG source for `execution_timeout` if tasks are killed unexpectedly.

## References

- Full API endpoint reference: `references/api_reference.md`
- [Airflow 3 REST API docs](https://airflow.apache.org/docs/apache-airflow/stable/stable-rest-api-ref.html)
- [Airflow 3 API security](https://airflow.apache.org/docs/apache-airflow/stable/security/api.html)
