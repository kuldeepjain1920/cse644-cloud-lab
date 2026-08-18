# CSE644 Lab — Terraform: Single VM (Phase 0: Foundation)

Provisions the single GCP VM, VPC, and firewall rules for the consolidated
CSE644 Docker + Kubernetes + GitOps lab. This is the deployment target used
for the graded Assignment 01/02/03 submission.

This directory is fully independent of `terraform/multi-vm/` and
`terraform/gke-autopilot/` (future extensions) — its own state, its own
lifecycle. `cd` in here and everything below applies only to this target.

## Prerequisites

- A GCP project created (e.g. `kuldeep-cse644-lab`), billing enabled
  (free credit applies)
- `gcloud` CLI authenticated: `gcloud auth application-default login`
- Terraform >= 1.7.0
- An SSH keypair (e.g. `~/.ssh/id_ed25519` / `.pub`)

## Usage

```
cd terraform/single-vm
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set project_id and admin_source_ip

terraform init
terraform plan
terraform apply
```

## After apply

```
terraform output ssh_command
```

Run the printed command to SSH in.

## Stopping / starting between sessions

```
gcloud compute instances stop cse644-lab-vm --zone=us-west1-b
gcloud compute instances start cse644-lab-vm --zone=us-west1-b
```

Note: the external IP is ephemeral, so it changes on every start. Re-run
`terraform output ssh_command` (or `terraform refresh` first) after starting
to get the current IP.

## Design notes

- VPC is dedicated to this lab (`cse644-vpc`), not shared or peered with
  any other project.
- Firewall rules restrict SSH and all web UI ports (HAProxy, apps, Argo CD,
  Grafana, Prometheus, NodePort range) to `var.admin_source_ip` only.
- `node_count` and the `cse644-node` network tag are already in place so a
  future Multi-VM k3s phase is an additive change, not a rewrite.
