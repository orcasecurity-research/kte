output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = nonsensitive(module.gke.cluster_endpoint)
}

output "kubectl_update_kubeconfig" {
  description = "gcloud command to connect to GKE"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id}"
}