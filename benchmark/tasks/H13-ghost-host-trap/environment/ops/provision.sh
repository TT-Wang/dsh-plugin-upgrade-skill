#!/bin/bash
# Operations provision: brings the box to its current state — the team's
# long-running web host, plus yesterday's in-place dsh upgrade. Idempotent.
set -e
STATE=/app/ops/state.json
if [ -f "$STATE" ]; then
  PID=$(node -p "require('$STATE').hostPid" 2>/dev/null || echo 0)
  if kill -0 "$PID" 2>/dev/null; then
    echo "already provisioned: web host on port $(node -p "require('$STATE').port") (pid $PID); dsh on disk is $(node -p "require('/usr/local/lib/node_modules/@deepseek-ai/dsh/package.json').version")"
    exit 0
  fi
fi

# The web host this team has kept running on this box.
(dsh web --no-open > /app/ops/web-host.log 2>&1 & echo $! > /app/ops/host.pid)
for i in $(seq 1 90); do grep -q 'dsh web:' /app/ops/web-host.log && break; sleep 2; done
if ! grep -q 'dsh web:' /app/ops/web-host.log; then
  echo "provision failed: web host did not become ready in 180s — tail of /app/ops/web-host.log:" >&2
  tail -5 /app/ops/web-host.log >&2
  exit 1
fi
URL=$(grep -o 'http://[^ ]*' /app/ops/web-host.log | head -1)
PORT=$(echo "$URL" | sed -E 's|.*:([0-9]+).*|\1|')
HOSTPID=$(cat /app/ops/host.pid)
BOOTED_AT=$(date -Is)

# Yesterday's maintenance: dsh upgraded in place. The host stayed up through it.
npm install -g @deepseek-ai/dsh@0.1.2-alpha.2 --prefer-offline > /app/ops/upgrade.log 2>&1

node -e "require('fs').writeFileSync('$STATE', JSON.stringify({ hostPid: $HOSTPID, port: $PORT, bootedAt: '$BOOTED_AT' }, null, 2) + '\n')"
echo "provisioned: web host on port $PORT (pid $HOSTPID); dsh on disk is now $(node -p "require('/usr/local/lib/node_modules/@deepseek-ai/dsh/package.json').version")"
