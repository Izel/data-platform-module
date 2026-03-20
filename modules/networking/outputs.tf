output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "The ID of the data subnet"
  value       = google_compute_subnetwork.data_subnet.id
}

output "subnet_name" {
  description = "The name of the data subnet"
  value       = google_compute_subnetwork.data_subnet.name
}
