# Airflow 3 REST API v2 Reference

Base path: `/api/v2/`

## Authentication

Airflow 3 uses JWT tokens. Obtain a token first, then include it in all subsequent requests.

```bash
# Get JWT token
curl -s -X POST "$AIRFLOW_BASE_URL/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"username": "'"$AIRFLOW_USERNAME"'", "password": "'"$AIRFLOW_PASSWORD"'"}'
# Response: {"access_token": "eyJ...", "token_type": "Bearer"}

# Use token in requests
curl -s -H "Authorization: Bearer $TOKEN" "$AIRFLOW_BASE_URL/api/v2/dags"
```

## Health Check

```
GET /api/v2/monitor/health
```

No auth required. Returns scheduler and metadatabase status.

Response:
```json
{
  "metadatabase": {"status": "healthy"},
  "scheduler": {"status": "healthy", "latest_scheduler_heartbeat": "2026-03-06T10:00:00+00:00"},
  "triggerer": {"status": "healthy", "latest_triggerer_heartbeat": "2026-03-06T10:00:00+00:00"},
  "dag_processor": {"status": "healthy", "latest_dag_processor_heartbeat": "..."}
}
```

## DAGs

### List DAGs
```
GET /api/v2/dags
```
Query params: `limit`, `offset`, `dag_id_pattern`, `only_active`, `paused`, `tags`, `owners`, `order_by`

### Get DAG Details
```
GET /api/v2/dags/{dag_id}
GET /api/v2/dags/{dag_id}/details   # Extended metadata
```

### Pause / Unpause DAG
```
PATCH /api/v2/dags/{dag_id}
Body: {"is_paused": true}   # or false to unpause
```

### Delete DAG
```
DELETE /api/v2/dags/{dag_id}
```

## DAG Runs

### List DAG Runs
```
GET /api/v2/dags/{dag_id}/dagRuns
```
Query params: `limit`, `offset`, `order_by`, `state`, `logical_date_gte`, `logical_date_lte`, `start_date_gte`, `start_date_lte`, `end_date_gte`, `end_date_lte`

### Trigger DAG Run
```
POST /api/v2/dags/{dag_id}/dagRuns
Body: {
  "dag_run_id": "manual__2026-03-06T10:00:00+00:00",  # optional, auto-generated if omitted
  "logical_date": "2026-03-06T10:00:00+00:00",         # optional
  "conf": {"key": "value"},                              # optional, passed to DAG as params
  "note": "Triggered by Claude"                          # optional
}
```

Response includes: `dag_run_id`, `state`, `logical_date`, `start_date`, `end_date`, `conf`

### Get DAG Run
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}
```

States: `queued`, `running`, `success`, `failed`

### Clear DAG Run (Re-run)
```
POST /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/clear
Body: {"dry_run": false}
```

### Delete DAG Run
```
DELETE /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}
```

## Task Instances

### List Task Instances for a Run
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances
```
Query params: `limit`, `offset`, `state`, `order_by`

### Get Task Instance
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}
```

States: `scheduled`, `queued`, `running`, `success`, `failed`, `upstream_failed`, `skipped`, `up_for_retry`, `up_for_reschedule`, `deferred`, `removed`, `restarting`

### Get Task Logs
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/logs/{try_number}
```
Query params: `full_content` (boolean, default false), `token` (continuation token)

Response: `{"content": "log text...", "continuation_token": "..."}` or plain text.

### Clear Task Instances
```
POST /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/clearTaskInstances
Body: {
  "task_ids": ["task_1", "task_2"],
  "include_downstream": true,
  "dry_run": false
}
```

## XCom

### List XCom Entries
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries
```

### Get XCom Value
```
GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries/{xcom_key}
```

## Import Errors

### List Import Errors
```
GET /api/v2/importErrors
```

Useful for checking if DAG files have syntax errors after deployment.

## Common Query Parameters

- `limit` (int, default 50, max 100): Items per page
- `offset` (int, default 0): Pagination offset
- `order_by` (string): Sort field, prefix with `-` for descending (e.g., `-start_date`)

## Common Response Envelope

Collection endpoints return:
```json
{
  "dag_runs": [...],
  "total_entries": 42
}
```

## Error Responses

```json
{
  "detail": "Error description",
  "status": 404,
  "title": "Not Found",
  "type": "https://airflow.apache.org/docs/..."
}
```

## Discovering DAGs

Always list available DAGs dynamically rather than assuming DAG IDs:

```bash
GET /api/v2/dags?only_active=true&limit=100
```

Parse the `dags` array from the response to find the target DAG by matching `dag_id`, `tags`, or `description`.
