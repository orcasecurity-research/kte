# Terraform .tfvars files
All Terraform projects rely on the configuration of [.tfvars](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/guides/terraform-vars) files. Below are boilerplates for each file:

eks.tfvars 
```terraform
region       = "" 
profile      = ""
vpc_name     = "" 
cluster_name = ""
```

gke.tfvars
  
```terraform
project_id   = ""
region       = ""
subnetwork   = ""
cluster_name = ""
```

gke.tfvars
  
```terraform
subscription_id     = ""
resource_group_name = ""
location            = ""
cluster_name        = ""
prefix              = "" # prefix name for resources created as part of cluster creation
```
# config.yaml
The [config.yaml](https://github.com/orcasecurity/kte/blob/master/config.yaml) file configures the deployment of clusters and tools. It is straightforward: mark `true` near the tools you'd like to test on the environment.

Example: run `polaris` on all cloud vendors.
> This will also provision EKS, GKE and AKS clusters, if they haven't been deployed yet.

```yaml
kubesec: false
kube-score: false
polaris:
  eks: true
  gke: true
  aks: true
kor:
  eks: false
  gke: false
  aks: false
trivy-operator:
  eks: false
  gke: false
  aks: false
checkov:
  eks: true
  gke: false
  aks: false
```
