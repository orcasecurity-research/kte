// GKE
module "gke" {
  source = "./modules"

  project_id   = var.project_id
  region       = var.region
  subnetwork   = var.subnetwork
  cluster_name = var.cluster_name
}

// Kubernetes & Helm
provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

resource "helm_release" "kte" {
  name  = "kte"
  chart = "../helm/kte"
}