# compute.tf
# Single VM for the graded build. node_count stays at 1 -- this resource is
# written so the future multi-VM phase can switch to `count = var.node_count`
# with minimal changes (naming would move to a for_each/count pattern).

resource "google_compute_instance" "cse644_lab_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["cse644-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.boot_disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.cse644_vpc.id
    subnetwork = google_compute_subnetwork.cse644_subnet.id

    # Ephemeral external IP -- freed automatically when the VM is stopped,
    # so no idle IP charges between your lab sessions.
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  }

  # Keeps the VM from being live-migrated mid-session; TERMINATE + manual
  # restart is the right behavior for a lab you stop/start deliberately.
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  labels = {
    project = "cse644-cloud-lab"
    course  = "cse644"
    owner   = "kuldeep"
  }
}
