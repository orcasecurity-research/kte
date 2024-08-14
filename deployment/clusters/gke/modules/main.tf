provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = var.subnetwork
  region        = var.region
  ip_cidr_range = "10.126.0.0/20"
  network       = "default"

  secondary_ip_range {
    range_name    = "${var.subnetwork}-pods"
    ip_cidr_range = "192.168.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${var.subnetwork}-services"
    ip_cidr_range = "172.16.0.0/24"
  }
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  network                    = "default"
  subnetwork                 = var.subnetwork
  ip_range_pods              = google_compute_subnetwork.subnetwork.secondary_ip_range[0].range_name
  ip_range_services          = google_compute_subnetwork.subnetwork.secondary_ip_range[1].range_name
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  deletion_protection        = false

  node_pools = [
    {
      name = "node-pool-1"
      machine_type = "e2-standard-4"
      autoscaling = true
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}