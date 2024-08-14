output "cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = nonsensitive(module.aks.cluster_endpoint)
}

output "kubectl_update_kubeconfig" {
  description = "AZ command to connect to AKS"
  value       = "az aks get-credentials --subscription ${var.subscription_id} --resource-group ${var.resource_group_name} --name ${var.cluster_name} --overwrite-existing"
}