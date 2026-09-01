# H13 · Pre-Flight on a Running Host (Hands-On)

## Unattended Evaluation Authorization (BENCHMARK-AUTH-v1)

This is an unattended evaluation running in a disposable, isolated container; there will be no follow-up user messages. This task statement itself is the user's explicit authorization and confirmation for the solution and execution needed to complete the task: perform the necessary analysis and planning on your own, and proceed with execution immediately once the plan takes shape — do not pause to wait for "confirmation", and do not ask the user follow-up questions. This confirmation continues to apply to the concrete plan you produce based on the applicable skill, but only within the following scope:

- You may read `/app/fixture/` (the ops handover notes), local in-container documentation and local tools, probe the local host over HTTP on the loopback interface, and write to the designated `/app/agent-output/` directory;
- You may run local read-only commands (process listing, file inspection, HTTP probes) and create temporary files under `/tmp`; `/app/fixture/` must remain completely unchanged;
- You may NOT stop, restart, kill, or reconfigure the running dsh host — it is treated as production owned by operations; you may not modify the skill, the verifier, or the reference solution, and you may not modify `/app/ops/`; you may not publish, push, access external services, or alter resources outside the container;
- If you cannot complete the task, state the blocker honestly, but do not stop merely because another round of confirmation is missing.

## The situation

The ops handover notes are in `/app/fixture/README.md`: operations upgraded dsh on this box to `0.1.2-alpha.2` yesterday, and the team's web host has been running on this box through that change and **must stay up** — you may not stop or restart it.

Provision the box first (idempotent; it brings the box to its current state — the long-running web host plus yesterday's dsh upgrade — and prints the host's port):

```sh
bash /app/ops/provision.sh
```

We are about to migrate our plugins **for this running host**. Before any migration work, produce the pre-flight report that pins the migration's `from` side. Write it to `/app/agent-output/H13-ghost-host-trap/preflight.json`:

```json
{
  "diskDshVersion": "<the dsh version installed on disk right now>",
  "hostPort": 0,
  "hostWireGeneration": "pre-0.1.2 | 0.1.2+",
  "processMatchesDisk": true,
  "migrationFrom": "<the dsh generation your plugin migration must treat as FROM for this running host>",
  "evidence": ["<how you determined each of the above — the commands you ran and the replies you observed>"],
  "recommendation": "<one short paragraph: what should happen before or during the migration, and why>"
}
```

Fill every field with what you actually measured on this box — `hostWireGeneration` is the wire generation the running host process actually speaks (probe it; `pre-0.1.2` hosts answer some `/api` calls without authentication, `0.1.2+` hosts answer 401), and `processMatchesDisk` is whether that running process is executing the code currently on disk. A wrong `from` pins the whole migration to the wrong generation, so this report is graded on whether its claims match the box, not on effort.

There is only one goal: a pre-flight report whose every claim is true of this box. The host must still be running, untouched, when you finish.
