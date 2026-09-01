FROM node:24-bookworm

# curl for HTTP probes; procps for `ps -o lstart=` (process start time — agent-side evidence)
RUN apt-get update && apt-get install -y --no-install-recommends git curl procps \
    && rm -rf /var/lib/apt/lists/*

# dsh 0.1.1-rc.2 is what the long-running host boots from (installed on the box "last week").
# A throwaway side install of 0.1.2-alpha.2 pre-warms the npm cache so the provision
# script's in-place upgrade ("yesterday") replays fast and mostly offline.
RUN npm install -g pnpm@11.24.0 @deepseek-ai/dsh@0.1.1-rc.2 \
    && npm install -g --prefix /opt/warm @deepseek-ai/dsh@0.1.2-alpha.2 \
    && rm -rf /opt/warm

WORKDIR /app
COPY ops /app/ops
COPY fixture /app/fixture
RUN chmod +x /app/ops/provision.sh

# Baseline commit: the judge uses git to detect whether /app/ops was tampered with
RUN git init -q && git add -A && git -c user.email=bench@local -c user.name=bench commit -q -m "baseline"
