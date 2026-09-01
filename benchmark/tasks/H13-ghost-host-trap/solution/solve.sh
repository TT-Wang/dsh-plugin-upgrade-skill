#!/bin/bash
# Oracle solution: provision, then pre-flight the RUNNING host by probing —
# never by reading version numbers off the disk (pre-flight step 1.5).
set -e
bash /app/ops/provision.sh

PORT=$(node -p "require('/app/ops/state.json').port")
PID=$(node -p "require('/app/ops/state.json').hostPid")
OUT=/app/agent-output/H13-ghost-host-trap
mkdir -p "$OUT"

# 1. Ask the process, not the disk: when did the process start vs when did the install change.
LSTART=$(ps -o lstart= -p "$PID")
DISK_MTIME=$(date -Is -r /usr/local/lib/node_modules/@deepseek-ai/dsh/package.json)
DISK_VERSION=$(node -p "require('/usr/local/lib/node_modules/@deepseek-ai/dsh/package.json').version")

# 2. Probe, don't read version numbers: unauthenticated agentPreset.list —
#    pre-0.1.2 hosts answer ok, 0.1.2+ hosts answer 401 (DSH-0.1.2-A1-08).
CODE=$(curl -s -o /tmp/pf-probe.json -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/api/agentPreset.list" \
  -H 'content-type: application/json' \
  -d '{"type":"client-request","rpcId":"preflight","method":"agentPreset.list","payload":{}}')
BODY=$(head -c 80 /tmp/pf-probe.json | tr -d '\n')

GEN='0.1.2+'
MATCH=true
if [ "$CODE" = "200" ] && grep -q '"ok":true' /tmp/pf-probe.json; then
  GEN='pre-0.1.2'
  MATCH=false
fi

PORT="$PORT" GEN="$GEN" MATCH="$MATCH" DISK_VERSION="$DISK_VERSION" CODE="$CODE" BODY="$BODY" LSTART="$LSTART" DISK_MTIME="$DISK_MTIME" PID="$PID" OUT="$OUT" node <<'EOF'
const { env } = process
const report = {
  diskDshVersion: env.DISK_VERSION,
  hostPort: Number(env.PORT),
  hostWireGeneration: env.GEN,
  processMatchesDisk: env.MATCH === 'true',
  migrationFrom: env.GEN === 'pre-0.1.2'
    ? 'the pre-0.1.2 generation the running process still executes (0.1.1 line) — not the 0.1.2-alpha.2 on disk'
    : env.DISK_VERSION,
  evidence: [
    `unauthenticated POST /api/agentPreset.list to 127.0.0.1:${env.PORT} returned HTTP ${env.CODE} with body ${env.BODY} — a 0.1.2+ host answers 401 here, so the process speaks the ${env.GEN} wire`,
    `process ${env.PID} started at "${env.LSTART}" while the dsh install on disk last changed at ${env.DISK_MTIME} — the process predates the upgrade and is executing the old code from memory`,
  ],
  recommendation: 'The running host is a ghost: disk says 0.1.2-alpha.2 but the process still executes the pre-0.1.2 code it loaded at boot. Pin the migration FROM to the pre-0.1.2 generation for anything that must work against this process, and schedule a restart with operations before validating 0.1.2-only behavior — restarting is an ops decision, not part of this pre-flight.',
}
require('node:fs').writeFileSync(`${env.OUT}/preflight.json`, JSON.stringify(report, null, 2) + '\n')
console.log('preflight written:', `${env.OUT}/preflight.json`)
EOF
