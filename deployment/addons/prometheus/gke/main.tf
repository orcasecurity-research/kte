provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_container_cluster" "gke" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.gke.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

resource "helm_release" "prom" {
  name             = "prom"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "60.2.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [file("../values.yaml")]
}

data "kubernetes_service" "dashboard" {
  depends_on = [helm_release.prom]

  metadata {
    name      = "prom-grafana"
    namespace = "monitoring"
  }
}