variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "subnetwork" {
  description = "GCP subnetwork name"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}