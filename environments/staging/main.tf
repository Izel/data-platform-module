locals {
  network_name = "${var.project_id}-${var.environment}-vpc"
}

# VPC Network 
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = local.network_name
  auto_create_subnetworks = false
  description             = "Data platform VPC for ${var.environment} environment"
}

# Subnet 
resource "google_compute_subnetwork" "data_subnet" {
  project                  = var.project_id
  name                     = "${var.environment}-data-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # Allows VMs to reach Google APIs without public IPs

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall: deny all ingress by default 
resource "google_compute_firewall" "deny_all_ingress" {
  project  = var.project_id
  name     = "${var.environment}-deny-all-ingress"
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  direction          = "INGRESS"
  source_ranges      = ["0.0.0.0/0"]
  destination_ranges = []

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Firewall: allow internal traffic within subnet 
resource "google_compute_firewall" "allow_internal" {
  project  = var.project_id
  name     = "${var.environment}-allow-internal"
  network  = google_compute_network.vpc.name
  priority = 1000

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = [var.subnet_cidr]
}
