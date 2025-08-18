# KTE: Kubernetes Testing Environment

![GitHub Stars](https://img.shields.io/github/stars/orcasecurity-research/kte?style=social)
![GitHub Fork](https://img.shields.io/github/forks/orcasecurity-research/kte?style=social)
![License](https://img.shields.io/github/license/orcasecurity-research/kte)

KTE (Kubernetes Testing Environment) is a comprehensive, vendor-agnostic project that enables easy testing of different open-source security offerings. This powerful tool currently supports:

* **polaris** - Best practices validation
* **kor** - Unused Kubernetes resource discovery
* **trivy-operator** - Vulnerability and security scanning
* **kubesec** - Security risk analysis
* **checkov** - Infrastructure as code scanning
* **kube-score** - Kubernetes object analysis

## 🚀 Features

KTE can provision a Kubernetes cluster via Terraform on all 3 major cloud service providers (AWS, GCP, and Azure), together with a predefined helm chart. A default test chart is provided, with plenty of misconfigurations for comprehensive testing.

We recommend users fork this project and add custom charts to utilize its full power in staging environments. Make sure to configure the Kubernetes nodes on each cluster to meet your specific requirements in terms of resources, size, and scale. You can customize this by editing each cluster's Infrastructure as Code (IaC) project. GKE and AKS support integrated node autoscaling; for EKS support, please explore [Karpenter](https://karpenter.sh/).

## 📖 Documentation

A comprehensive introduction write-up of this project, including detailed information on how it works and what to expect, can be found in the [Orca Research Pod](https://orca.security/resources/blog/).

## 🏗️ Architecture

![Cluster Design](docs/cluster-design.png)

## ⚡ Quick Start

### Prerequisites

The clusters, helm chart, and most tools are provisioned using **Terraform**. **Go**, **kubectl**, and **yq** are also required. You must use a **Unix** machine OR activate WSL to run the main CLI tool. We also recommend installing and using **helm** for troubleshooting and debugging purposes.

### 🔧 Configuration

You will need to create a `.tfvars` file for each vendor. Follow the detailed instructions in [docs/configuration.md](docs/configuration.md).

```bash
git clone https://github.com/orcasecurity-research/kte.git
cd kte

mkdir deployment/vars
touch deployment/vars/{eks,gke,aks}.tfvars
```

### 🏃 Running

Everything you can do is managed by the main CLI tool. Follow its help manual for complete usage instructions. It relies on relative paths, so make sure to run it from the root directory.

```bash
./kte.sh
```

## 🤝 Community

We encourage bug reports and feature requests through [discussions](https://github.com/orcasecurity-research/kte/discussions), as well as general questions. Follow the [contribution guidelines](CONTRIBUTING.md) for more information. When participating, please adhere to this project's [code of conduct](CODE_OF_CONDUCT.md). 

**Note:** Don't open issues as they will be immediately closed - maintainers triage discussions and then create issues.

## ⚠️ Cost Disclaimer

> **Warning:** This project will incur cloud costs associated with the deployment of managed Kubernetes clusters. Since the project can be customized, cost estimation varies. By default, the following machine types are used:
> 
> * **EKS**: t3.large
> * **GKE**: e2-standard-4  
> * **AKS**: Standard_D2s_v3
> 
> Please perform due diligence to avoid unexpected costs. All vendors operate on a pay-as-you-go model with a **$0.10/hour** fee for the cluster's control plane. The hourly prices for the default machine types in the configured regions are: **$0.0832**, **$0.1344**, and **$0.096** respectively. 
>
> **Current estimated price for the default EKS testing environment: $0.266/hour** *(verified August 14, 2024)*
>
> The owners and maintainers of this project are not responsible for any unexpected costs.

## 📄 License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Special thanks to the open-source security community and all contributors who make this project possible.