# variables.tf
# All the knobs for this lab. Defaults reflect the decisions made for the
# CSE644 single-VM build: us-west1 (closest low-latency region to Mountain
# View that avoided the us-central1 e2 capacity stockouts), e2-standard-4
# (sized to run Argo CD + Prometheus + Grafana together in Assignment 03
# without needing a resize), single node for now.
#
# node_count is exposed even though it's fixed at 1 today, so the future
# Multi-VM k3s phase is a variable change, not a rewrite.

variable "project_id" {
  description = "GCP project ID for this lab (kept fully separate from devsecops-lab)"
  type        = string
  # e.g. "kuldeep-cse644-lab" -- set this in terraform.tfvars, not here
}

variable "region" {
  description = "GCP region for the lab VM"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP zone for the lab VM"
  type        = string
  default     = "us-west1-b"
}

variable "machine_type" {
  description = "GCE machine type. e2-standard-4 (4 vCPU/16GB) covers Docker + k3s + Argo CD + Prometheus/Grafana running together in Assignment 03."
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "vm_name" {
  description = "Name of the lab VM"
  type        = string
  default     = "cse644-lab-vm"
}

variable "node_count" {
  description = "Number of k3s nodes. Fixed at 1 for the graded single-VM build; bump this (and the future multi-VM module) for the Phase 4 extension."
  type        = number
  default     = 1
}

variable "admin_source_ip" {
  description = "Your current public IP in CIDR form (e.g. 1.2.3.4/32), used to restrict SSH and web UI access (Argo CD, Grafana, HAProxy, NodePort range) to just you. Find yours with `curl -s ifconfig.me`."
  type        = string
  # no default on purpose -- must be set explicitly in terraform.tfvars
}

variable "ssh_public_key_path" {
  description = "Path to your local SSH public key, injected into the VM's metadata for login"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_username" {
  description = "Username to SSH in as (must match the key comment/OS login user)"
  type        = string
  default     = "testuser"
}
