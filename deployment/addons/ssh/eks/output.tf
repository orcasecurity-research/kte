output "ssh_server" {
  description = "Address of the ssh server"
  value       = "${kubernetes_service.ssh-server.status.0.load_balancer.0.ingress.0.hostname}"
}