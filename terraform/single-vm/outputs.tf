# outputs.tf

output "vm_external_ip" {
  description = "External IP of the lab VM (changes each time the VM is stopped/started, since it's ephemeral)"
  value       = google_compute_instance.cse644_lab_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Ready-to-run SSH command"
  value       = "ssh ${var.ssh_username}@${google_compute_instance.cse644_lab_vm.network_interface[0].access_config[0].nat_ip}"
}

output "vpc_name" {
  value = google_compute_network.cse644_vpc.name
}
