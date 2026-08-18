# versions.tf
# Pins the Terraform and provider versions so `terraform init` is reproducible
# across machines/sessions (important since you stop/start this VM often).

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
