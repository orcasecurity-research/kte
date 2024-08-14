// AKS
module "aks" {
  source = "./modules"

  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = var.cluster_name
  prefix              = var.prefix
}

// Kubernetes & Helm
provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

resource "helm_release" "kte" {
  name  = "kte"
  chart = "../../../helm/kte"
}