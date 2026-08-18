# firewall.tf
# All rules are scoped to var.admin_source_ip (your current public IP) --
# nothing here is open to 0.0.0.0/0. Since the VM gets an ephemeral external
# IP (see compute.tf) for simplicity, source-IP restriction is the security
# boundary instead of the IAP-tunnel + Cloud NAT pattern used in
# devsecops-lab. That pattern is available as a later hardening step if you
# want it, but adds setup complexity that isn't needed for a graded lab.

resource "google_compute_firewall" "allow_ssh_admin" {
  name    = "cse644-allow-ssh-admin"
  network = google_compute_network.cse644_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_source_ip]
  target_tags   = ["cse644-node"]
  description   = "SSH access restricted to admin IP only"
}

resource "google_compute_firewall" "allow_web_admin" {
  name    = "cse644-allow-web-admin"
  network = google_compute_network.cse644_vpc.id

  allow {
    protocol = "tcp"
    # 80/443    -> HAProxy / Nginx
    # 8888      -> Python web server (Assignment 01/02 requirement)
    # 8080      -> Argo CD UI
    # 3000      -> Grafana
    # 9090      -> Prometheus
    # 30000-32767 -> Kubernetes NodePort range (Assignment 02 exposure demo)
    ports = ["80", "443", "8888", "8080", "3000", "9090", "30000-32767"]
  }

  source_ranges = [var.admin_source_ip]
  target_tags   = ["cse644-node"]
  description   = "Web/UI access (HAProxy, apps, Argo CD, Grafana, Prometheus, NodePort) restricted to admin IP"
}

# Self-referencing rule for future multi-node k3s (Phase 4 extension):
# allows nodes tagged cse644-node to reach each other on the k3s API,
# flannel VXLAN, and kubelet ports. Harmless with a single node today --
# there's simply nothing else to talk to -- but means the multi-VM phase
# doesn't need a firewall rewrite, just more instances with this same tag.
resource "google_compute_firewall" "allow_internal_k3s" {
  name    = "cse644-allow-internal-k3s"
  network = google_compute_network.cse644_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6443", "10250"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  source_tags = ["cse644-node"]
  target_tags = ["cse644-node"]
  description = "k3s control-plane API, kubelet, and flannel VXLAN between cluster nodes"
}
