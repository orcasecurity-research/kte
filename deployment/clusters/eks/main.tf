// EKS
module "eks" {
  source = "./modules"

  region       = var.region
  profile      = var.profile
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

// Kubernetes & Helm
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
      command     = "aws"
    }
  }
}

resource "helm_release" "kte" {
  name  = "kte"
  chart = "../helm/kte"
}