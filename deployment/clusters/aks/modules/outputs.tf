output "cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = module.aks.host
}

output "client_certificate" {
  description = "AKS admin client certificate"
  value       = module.aks.client_certificate
}

output "client_key" {
  description = "AKS admin client key"
  value       = module.aks.client_key
}

output "cluster_ca_certificate" {
  description = "AKS cluster ca certificate"
  value       = module.aks.cluster_ca_certificate
}
