output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "Certificate authority of EKS control plane"
  value       = module.eks.cluster_certificate_authority
}

output "kubectl_update_kubeconfig" {
  description = "AWSCLI command to connect to EKS"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name} --profile ${var.profile}"
}