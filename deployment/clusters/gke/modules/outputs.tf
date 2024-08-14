output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = module.gke.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster ca certificate"
  value       = module.gke.ca_certificate
}