# Ops handover notes (this box)

- The team's dsh **web host** runs on this box and must stay up. Do not stop or
  restart it — operations owns its lifecycle.
- 2026-08-31: dsh upgraded in place to **0.1.2-alpha.2** ✅ (`npm install -g`,
  confirmed with `dsh --version` afterwards). Nothing else was touched.
- Provisioning is replayed by `bash /app/ops/provision.sh` (idempotent); it prints
  the host's port. Runtime state lands in `/app/ops/state.json`, host log in
  `/app/ops/web-host.log`.
- Next planned work: migrate our plugins for this host. Pre-flight report first.
