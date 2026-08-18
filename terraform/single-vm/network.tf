# network.tf
# Dedicated VPC for this lab -- intentionally NOT peered or shared with the
# devsecops-lab VPCs, per the requirement to keep these projects independent.
# Even living in separate GCP projects, a dedicated VPC here (rather than
# "default") keeps things explicit and easy to reason about.

resource "google_compute_network" "cse644_vpc" {
  name                    = "cse644-vpc"
  auto_create_subnetworks = false
  description             = "Dedicated VPC for the CSE644 Cloud Computing lab (Docker + Kubernetes + GitOps)"
}

resource "google_compute_subnetwork" "cse644_subnet" {
  name          = "cse644-subnet-${var.region}"
  ip_cidr_range = "10.30.0.0/24"
  region        = var.region
  network       = google_compute_network.cse644_vpc.id

  # Enables Google API access (Container Registry/Artifact Registry, etc.)
  # without needing a public IP or Cloud NAT for that traffic specifically.
  private_ip_google_access = true
}
