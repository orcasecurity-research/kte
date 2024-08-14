output "dashboard_ip" {
  description = "URL of the grafana dashboard"
  value       = "http://${data.kubernetes_service.dashboard.spec.0.cluster_ip}"
}