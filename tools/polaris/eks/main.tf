provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
      command     = "aws"
    }
  }
}

resource "helm_release" "polaris" {
  name             = "polaris"
  repository       = "https://charts.fairwinds.com/stable"
  chart            = "polaris"
  namespace        = "polaris"
  create_namespace = true
}

data "kubernetes_service" "dashboard" {
  depends_on = [helm_release.polaris]

  metadata {
    name      = "polaris-dashboard"
    namespace = "polaris"
  }
}