# CSE644 Lab — Terraform: Multi-VM k3s (Phase 4 — not started)

Planned extension: 3-node k3s cluster (1 control-plane + 2 workers) as
separate GCE VMs, for real multi-node scheduling and workload HA beyond
what the single-VM build demonstrates.

Not built yet. Will reuse the `cse644-node` network tag and firewall
pattern from `terraform/single-vm/`, factored into a shared
`terraform/modules/network` module so both targets stay in sync.

Independent from `terraform/single-vm/` and `terraform/gke-autopilot/` —
own state, own lifecycle, applied separately.
