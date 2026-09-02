# H13 Reference Solution

The trap: the box's disk says dsh `0.1.2-alpha.2` (yesterday's in-place upgrade), but the
web host process has been running since before that upgrade — it still executes the
`0.1.1-rc.2` code it loaded at boot. Every disk-side signal (`dsh --version`,
`package.json`, install mtime for anything but the comparison below) reports the new
version; only the process's replies tell the truth.

Two checks, both from pre-flight step 1.5 of the `plugin-upgrade` skill:

1. **Ask the process, not the disk** — `ps -o lstart= -p <hostPid>` against the install's
   last-change time: the process predates the upgrade, so it cannot be running the bytes
   now on disk.
2. **Probe, don't read version numbers** — unauthenticated
   `POST /api/agentPreset.list`: a `0.1.2+` host answers 401 (`DSH-0.1.2-A1-08`); this
   process answers `ok:true`, i.e. the `pre-0.1.2` wire.

So the report pins `hostWireGeneration: "pre-0.1.2"`, `processMatchesDisk: false`, and
`migrationFrom` to the pre-0.1.2 generation — while the host stays untouched: stopping
or restarting it is an operations decision (rollup R-12), not part of the pre-flight,
and the task forbids it.

The naive path — `dsh --version` / reading `package.json` and reporting `0.1.2+`,
`processMatchesDisk: true` — produces a report whose every downstream migration decision
is pinned one generation wrong; the judge caps that report at 20/100.

`solve.sh` is the executable form: provision, one probe, one `lstart` comparison, write
`preflight.json`.
