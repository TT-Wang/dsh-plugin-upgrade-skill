# H13-ghost-host-trap · local validation report (2026-09-01, re-run 2026-09-02 after review fixes)

Environment: Docker 20.10.24 on macOS host, image `node:24-bookworm`; network public
(npm registry). All runs from this repo's task directory, unmodified.

## 1. Mechanism proof (the ghost is real, not simulated)

Prototype run inside a fresh container:

- `npm i -g @deepseek-ai/dsh@0.1.1-rc.2` → `dsh --version` = `0.1.1-rc.2`; `dsh web
  --no-open` becomes ready on port 3080, ready line carries **no** `?token=` (the
  pre-auth generation).
- Unauthenticated `POST /api/agentPreset.list` → HTTP 200, `"ok":true` (pre-0.1.2 wire).
- **In-place** `npm i -g @deepseek-ai/dsh@0.1.2-alpha.2` while the process keeps
  running → `dsh --version` on disk now reports `0.1.2-alpha.2`.
- Same probe against the same process → still HTTP 200 `"ok":true`: the process keeps
  executing the pre-0.1.2 code it loaded at boot. Disk and process disagree — exactly
  the ghost that pre-flight step 1.5 exists for.

## 2. Oracle run (solution/solve.sh → tests/judge.mjs)

`bash /solution/solve.sh` then `node /tests/judge.mjs` in a fresh container:

```json
{"score":100,"max":100,"reasons":["+40 hostWireGeneration = pre-0.1.2 (matches the running process)","+20 processMatchesDisk = false","+15 migrationFrom pins the old generation","+10 probe-grade evidence (probe reply or process-start comparison)","+5 diskDshVersion = 0.1.2-alpha.2 and hostPort matches the provisioned port","+10 host untouched (provisioned pid alive, still answers the old wire)"]}
```

## 3. Negative controls

- Naive report (trusts the disk: `hostWireGeneration: "0.1.2+"`,
  `processMatchesDisk: true`, evidence = `dsh --version`): **15/100** — only the
  disk-facts tier (+5, diskDshVersion **and** correct hostPort) and host-untouched
  (+10) survive; every generation claim scores zero. (The ≤20 trap cap is a backstop;
  the raw score is already below it.)
- No report at all: **0/100** (`no report at /app/agent-output/H13-ghost-host-trap/preflight.json`).
- Ops tamper (oracle solve, then append one line to the tracked `ops/provision.sh`):
  **0/100** — the judge's `git -C /app status --porcelain -- ops` check catches
  `M ops/provision.sh` and short-circuits. Provision's own runtime outputs
  (`state.json`, `host.pid`, logs) are untracked and did not false-positive in the
  oracle/naive runs.

Score spread oracle/naive/none/tamper = **100 / 15 / 0 / 0**.

## 4. Validators

- `node benchmark/scripts/validate-task-registry.mjs` → OK: 24 tasks, registries consistent
- `node benchmark/scripts/validate-execution-contract.mjs` → OK: 24 tasks use BENCHMARK-AUTH-v1
- `node scripts/validate.mjs` → Validation OK

## Boundaries

- The judge classifies by wire replies and process liveness only; it does not attempt
  to prove which bytes are mapped into the process's memory.
- Runtime provision performs one cache-warmed `npm install -g` (network public, same
  posture as M5/H8); a registry outage during provision fails loudly, not silently.
- Validated on this machine only; not yet run under the Harbor harness itself.
