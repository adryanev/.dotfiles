---
name: api-test
description: "This skill should be used to run a backend service locally and perform end-to-end API testing via curl. It automatically manages the server lifecycle (start if not running), tests endpoints sequentially against the live service, and produces a Test Execution Document (TED) in docs/reports/. Triggers on 'e2e test', 'end to end test', 'test the API', 'run the service and test', 'test endpoints', 'create TED', or when the user wants to verify API behavior against a running server."
---

# End-to-End API Test

## Overview

Autonomous end-to-end testing workflow that:
1. Ensures the server is running (starts it if not)
2. Tests endpoints one by one with curl
3. Produces a Test Execution Document (TED) in `docs/reports/`

## Workflow

Follow these steps in order. Do not skip steps.

### Step 1: Pre-flight Checks

1. Read `.env` (or equivalent config) in the project root to extract:
   - `PORT` (detect from config, default `8000`)
   - Any API keys or auth tokens needed for authenticated endpoints
   - `DATABASE_URL` and `REDIS_URL` (if applicable, for environment info)
2. Capture environment info for the TED:
   ```bash
   # Detect language/runtime version
   go version 2>/dev/null || python3 --version 2>/dev/null || node --version 2>/dev/null
   git branch --show-current
   git rev-parse --short HEAD
   ```
3. Examine the project to understand:
   - What endpoints exist (check OpenAPI spec, route definitions, or handler files)
   - Which endpoints require authentication
   - Which endpoints use caching
   - What the health/readiness endpoint is

### Step 2: Ensure Server is Running

Check if the server is already listening on the port:

```bash
lsof -i :$PORT -t 2>/dev/null
```

**If a process IS found:** Verify it's responding by hitting the health/readiness endpoint:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health
```

- If 200 → server is healthy, skip to Step 3
- If not 200 → warn user that port is occupied but not responding, ask what to do

**If NO process is found:** Start the server. Detect the project type and try appropriate strategies:

**Go projects:**
- Strategy A: `make api-dev` or `make dev` (if Makefile exists with dev target)
- Strategy B: `go run ./cmd/api` or `go run ./cmd/server` or `go run main.go`
- Strategy C: Build and run binary

**Python projects:**
- Strategy A: `make dev` or relevant Makefile target
- Strategy B: `uvicorn` or `gunicorn` or `python -m flask run`

**Node.js projects:**
- Strategy A: `npm run dev` or `yarn dev`
- Strategy B: `node server.js` or `node index.js`

Use `run_in_background: true`. Set `SERVER_STARTED_BY_SKILL=true` to track cleanup.

**Important for Go projects:** `envconfig` reads OS env vars, not `.env` files. When running the binary directly, you MUST source `.env` first with `set -a; source .env; set +a`.

### Step 3: Wait for Readiness

Poll the health/readiness endpoint until the service is fully operational:

```bash
for i in $(seq 1 30); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health)
  if [ "$STATUS" = "200" ]; then
    echo "Service ready"
    break
  fi
  echo "Waiting for service... (attempt $i)"
  sleep 2
done
```

If not ready within 60 seconds, stop and report the failure.

Verify and capture readiness details:
```bash
curl -s http://localhost:$PORT/health | python3 -m json.tool
```

### Step 4: Determine Test Scope

1. If the user specified a feature or endpoint in the invocation arguments, use that scope directly.
2. Otherwise, discover available endpoints by reading:
   - OpenAPI spec (e.g., `api/openapi.yaml`, `openapi.json`)
   - Route definitions in source code
   - README or API documentation
3. Present discovered endpoint groups to the user and ask which to test:
   - Individual endpoint groups
   - All endpoints

### Step 5: Execute Tests (One by One)

Test each endpoint **sequentially** (not in parallel — respect rate limits).

For each endpoint, execute these test categories as applicable:

#### 5.1 Test Categories

| Category | When to Run | What to Test |
|----------|-------------|--------------|
| Happy path | Always | Valid request, verify 200 and correct response structure |
| i18n | Endpoints with user-facing messages (if i18n is supported) | Repeat with different `Accept-Language`, verify localized response |
| Error cases | Endpoints with path/query params | Invalid params → 400, non-existent resource → 404 |
| Cache validation | Endpoints with caching | Compare 1st vs 2nd call timing, verify identical responses |

**Detecting cached endpoints:** Search handler code for Redis/cache patterns (`redis.Get`, `redis.Set`, `cache.Get`, etc.)

**Detecting authenticated endpoints:** Search for auth middleware, API key checks, or JWT validation in handlers/routes.

#### 5.2 Curl Templates

**GET (public):**
```bash
curl -s -w "\n---\nHTTP_STATUS: %{http_code}\nTIME: %{time_total}s\nSIZE: %{size_download} bytes\n" \
  -H "Accept: application/json" \
  "http://localhost:$PORT/ENDPOINT"
```

**GET (authenticated):**
```bash
curl -s -w "\n---\nHTTP_STATUS: %{http_code}\nTIME: %{time_total}s\nSIZE: %{size_download} bytes\n" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:$PORT/ENDPOINT"
```

**POST:**
```bash
curl -s -w "\n---\nHTTP_STATUS: %{http_code}\nTIME: %{time_total}s\nSIZE: %{size_download} bytes\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' \
  "http://localhost:$PORT/ENDPOINT"
```

**Cache validation (timing comparison):**
```bash
TIME1=$(curl -s -o /dev/null -w "%{time_total}" "http://localhost:$PORT/ENDPOINT")
TIME2=$(curl -s -o /dev/null -w "%{time_total}" "http://localhost:$PORT/ENDPOINT")
echo "First: ${TIME1}s, Cached: ${TIME2}s"
```

#### 5.3 Recording Results

For each test, record:
- Endpoint path and method
- Description of what's being tested
- HTTP status code (actual vs expected)
- Complete JSON response body (pipe through `python3 -m json.tool` for formatting)
- Response time
- Pass/fail determination

**Important:** Capture the COMPLETE response body for every test. Never truncate or summarize.

#### 5.4 Test Execution Order

For each endpoint group, test in this order:
1. Happy path with default parameters
2. Happy path with specific parameters/filters
3. i18n validation (if applicable)
4. Error handling (invalid input, not found)
5. Cache validation (if cached endpoint)

### Step 6: Generate Test Execution Document (TED)

Create the TED at `docs/reports/TEST_EXECUTION_REPORT_<FEATURE>.md`.

If testing all features, name it `TEST_EXECUTION_REPORT_FULL.md`.
If testing a specific feature, name it `TEST_EXECUTION_REPORT_<FEATURE>.md`.

#### Response Body Policy

**Always include complete JSON response bodies** — never truncate or summarize. Use `<details>` blocks to keep the report scannable while preserving full data for reviewers.

| Guideline | Detail |
|-----------|--------|
| Include full responses | Show the real output exactly as returned |
| Use `<details>` blocks | Wrap responses in collapsible sections |
| Pretty-print JSON | Use `python3 -m json.tool` or `jq .` |
| Error responses too | Include the exact error text/JSON verbatim |

#### TED Template

```markdown
# Test Execution Document: <Feature/Scope>

**Generated:** YYYY-MM-DD
**Branch:** <current git branch>
**Base URL:** http://localhost:<PORT>
**Status:** ALL TESTS PASSED | TESTS FAILED

## Summary

| Category | Tests | Passed | Failed | Avg Response Time |
|----------|-------|--------|--------|-------------------|
| Happy Path | X | X | 0 | X.XXs |
| i18n | X | X | 0 | X.XXs |
| Error Handling | X | X | 0 | X.XXs |
| Cache Validation | X | X | 0 | X.XXs |
| **Total** | **X** | **X** | **0** | **X.XXs** |

## Environment

| Item | Value |
|------|-------|
| Runtime Version | <language/runtime version> |
| Branch | <git branch> |
| Commit | <git short SHA> |
| Database | <healthy/unhealthy (host:port/db) or N/A> |
| Cache | <healthy/unhealthy (host:port) or N/A> |

## Test Results

### <Endpoint Group Name>

#### Happy Path

| # | Endpoint | Method | Description | Status | Expected | Result | Time |
|---|----------|--------|-------------|--------|----------|--------|------|
| 1 | /v1/feature | GET | Default params | 200 | 200 | PASS | 0.05s |

<details>
<summary>Request/Response Details</summary>

**Request:**
\`\`\`bash
curl -s -H "Accept: application/json" "http://localhost:8000/v1/feature"
\`\`\`

**Response:**
\`\`\`json
{
    "complete": "json response here"
}
\`\`\`

- Observations about the response data

</details>

#### i18n Validation

| # | Endpoint | Language | Expected Behavior | Result |
|---|----------|----------|-------------------|--------|
| 1 | /v1/feature?page=0 | en | English error | PASS |
| 2 | /v1/feature?page=0 | id | Localized error | PASS |

<details>
<summary>i18n Response Details</summary>

**Language A:**
\`\`\`json
{"error": "English message"}
\`\`\`

**Language B:**
\`\`\`json
{"error": "Localized message"}
\`\`\`

</details>

#### Error Handling

| # | Endpoint | Scenario | Status | Expected | Result | Time |
|---|----------|----------|--------|----------|--------|------|
| 3 | /v1/feature/INVALID | Invalid ID | 400 | 400 | PASS | 0.01s |
| 4 | /v1/feature/NOTFOUND | Not found | 404 | 404 | PASS | 0.01s |

<details>
<summary>Error Response Details</summary>

**Test 3 — Invalid ID:**
\`\`\`bash
curl -s "http://localhost:8000/v1/feature/INVALID"
\`\`\`

**Response:**
\`\`\`
exact error text here
\`\`\`

</details>

### Cache Validation

| # | Endpoint | Description | First Call | Cached Call | Speedup |
|---|----------|-------------|------------|-------------|---------|
| 5 | /v1/feature | Cache hit | 0.050s | 0.008s | 6.3x |

Both calls return 200 with identical response sizes, confirming caching.

## Validation Checklist

- [ ] All endpoints return correct status codes
- [ ] Response Content-Type is application/json
- [ ] Error responses include appropriate error messages
- [ ] i18n works for supported languages (where applicable)
- [ ] Authenticated endpoints reject missing/invalid credentials
- [ ] Caching reduces response times on subsequent calls (where applicable)
- [ ] Empty results return valid empty-collection structure
- [ ] Response times are within acceptable range (<100ms cached, <2s uncached)

## Commands Executed

\`\`\`bash
# All curl commands used during testing, in execution order
\`\`\`

## Conclusion

<Summary: total tests, pass/fail, key observations, data availability notes, readiness>
```

### Step 7: Cleanup

After all tests are complete and the TED is written:

1. **If `SERVER_STARTED_BY_SKILL=true`**: Stop the server process
   ```bash
   # Kill the server started by this skill
   pkill -f "./bin/api" 2>/dev/null || pkill -f "go run" 2>/dev/null
   # or kill the PID captured during startup
   ```
2. **If the server was already running**: Leave it running (don't kill it)
3. Inform the user of the TED location
4. Summarize pass/fail counts

## Important Notes

- **Sequential execution**: Test endpoints one by one. Do not run curl requests in parallel (respect rate limits)
- **Complete responses**: Always include full JSON response bodies. Use `<details>` blocks for scannability
- **Database data**: Tests depend on actual data. Empty results are not failures — note this in the TED
- **Env var loading**: When running binaries directly, ensure environment variables are loaded from `.env` or equivalent
- **Adapt to the project**: Read the project structure, Makefile, and config to determine the correct commands for starting the server, the health endpoint path, authentication mechanism, etc.
