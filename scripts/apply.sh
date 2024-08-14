#!/bin/bash

# Dependencies check
terraform -version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Terraform can't be found."
  exit 1
fi

kubectl >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Kubectl can't be found."
  exit 1
fi

go version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Golang can't be found."
  exit 1
fi

yq --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "yq can't be found."
  exit 1
fi

# yq
eks=$(yq 'with_entries(select(.value.eks == true)) | keys | .[]' config.yaml)
gke=$(yq 'with_entries(select(.value.gke == true)) | keys | .[]' config.yaml)
aks=$(yq 'with_entries(select(.value.aks == true)) | keys | .[]' config.yaml)
kubesec=$(yq '.kubesec' config.yaml)
kubescore=$(yq '.kube-score' config.yaml)

# Dependencies check #2
if [ $kubescore = true ]; then
  kube-score version >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "kube-score can't be found. Install using brew, or download a release."
    exit 1
  fi
fi

# TFVARs setup
EKS_TFVAR="deployment/vars/eks.tfvars"
GKE_TFVAR="deployment/vars/gke.tfvars"
AKS_TFVAR="deployment/vars/aks.tfvars"

# Prometheus setup
prom=("trivy-operator" "kor")

echo "Run static checks"; sleep 2
# Static checks
# 1) kubesec
if [ $kubesec = true ]; then
  if [ -e "dashboards/kubesec.html" ]; then
    echo -e " ➝ kubesec:\tDashboard exists. Delete kubesec.html to re-execute."; sleep 2
  else
    echo -n "Running kubesec ... "; sleep 2
    if ! [ -f "tools/kubesec/kubesec" ]; then
      GOBIN=$PWD/tools/kubesec go install github.com/controlplaneio/kubesec/v2@latest
    fi
    jsondata=$(find deployment/clusters/helm/kte/templates/ -name '*.yaml' -exec tools/kubesec/kubesec scan {} \; | jq '.[]' | jq -s '.' | jq -c '.' | sed 's/[\/&]/\\&/g')
    sed "/const jsonData/ s/{}/$jsondata/" tools/kubesec/template.html > dashboards/kubesec.html
    sed -i '' "/class=\"kubesec\"/ s|href=\"[^\"]*\"|href=\"kubesec.html\"|" dashboards/index.html
    echo "done"; sleep 2
  fi
fi

# 2) kube-score
if [ $kubescore = true ]; then
  if [ -e "dashboards/kube-score.html" ]; then
    echo -e " ➝ kube-score:\tDashboard exists. Delete kube-score.html to re-execute."; sleep 2
  else
    echo -n "Running kube-score ... "; sleep 2
    if ! [ -f "tools/kube-score/kube-score" ]; then
      GOBIN=$PWD/tools/kube-score go install github.com/zegl/kube-score/cmd/kube-score@latest
    fi
    tools/kube-score/kube-score score deployment/clusters/helm/kte/templates/*.yaml > tools/kube-score/kube-score_output.txt
    sed -i '' -e 's/&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g' \
      -e 's/"/\&quot;/g' \
      -e "s/'/\&apos;/g" \
      -e 's/CRITICAL/<span class="critical">CRITICAL<\/span>/g' tools/kube-score/kube-score_output.txt
    sed '/<!-- INSERT KUBECTL OUTPUT HERE -->/r tools/kube-score/kube-score_output.txt' \
      tools/kube-score/template.html > dashboards/kube-score.html
    sed -i '' "/class=\"kube-score\"/ s|href=\"[^\"]*\"|href=\"kube-score.html\"|" dashboards/index.html
    echo "done"; sleep 2
  fi
fi
echo

echo "Run IaC checks according to config.yaml"
# Dynamic / Terraform checks
# 1) EKS
if [ -n "$eks" ]; then
  echo "Deploying EKS cluster ..."; sleep 2
  if ! [ -e $EKS_TFVAR ]; then
    echo "eks.tfvars doesn't exist under deployment/vars."
    exit 1
  fi

  tfstate=$(terraform -chdir=$PWD/deployment/clusters/eks show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, EKS was already deployed."
  else
    terraform -chdir=$PWD/deployment/clusters/eks init
    terraform -chdir=$PWD/deployment/clusters/eks apply -var-file \
      $PWD/deployment/vars/eks.tfvars -auto-approve -compact-warnings
    if [ $? -ne 0 ]; then
      echo "Terraform failed, please examine the error above. Exiting 👋"
      exit 1
    fi
    echo "EKS done."; sleep 2
    echo
  fi

  kubectl_update_kubeconfig=$(terraform -chdir=$PWD/deployment/clusters/eks output -raw kubectl_update_kubeconfig)

  while IFS= read -r tool; do
    echo "Deploying $tool on EKS ..."; sleep 2
    tfstate=$(terraform -chdir=$PWD/tools/$tool/eks show)
    if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
    && [ "$tfstate" != "No state." ]; then
      echo -e " ➝ State file isn't empty, $tool on EKS was already deployed."
      continue
    else
      # -- deploy prometheus if needed -- #
      for item in "${prom[@]}"; do
        if [ $item = $tool ]; then
          tfstate=$(terraform -chdir=$PWD/deployment/addons/prometheus/eks show)
          if [ "$tfstate" = "The state file is empty. No resources are represented." ] \
          || [ "$tfstate" = "No state." ]; then
            terraform -chdir=$PWD/deployment/addons/prometheus/eks init
            terraform -chdir=$PWD/deployment/addons/prometheus/eks apply \
              -var-file $PWD/deployment/vars/eks.tfvars -auto-approve -compact-warnings

            if [ $? -ne 0 ]; then
              echo "Terraform failed, please examine the error above. Exiting 👋"
              exit 1
            fi
          fi
          # -- sed index.html with prom dashboard -- #
          sed -i '' "/class=\"$tool\".*eks/ s|href=\"[^\"]*\"|href=\"$(terraform \
          -chdir=$PWD/deployment/addons/prometheus/eks output -raw dashboard_ip)\"|" \
          dashboards/index.html
        fi
      done

      terraform -chdir=$PWD/tools/$tool/eks init
      terraform -chdir=$PWD/tools/$tool/eks apply -var-file \
        $PWD/deployment/vars/eks.tfvars -auto-approve -compact-warnings

      if [ $? -ne 0 ]; then
        echo "Terraform failed, please examine the error above. Exiting 👋"
        exit 1
      fi
    fi

    # -- sed index.html with private dashboard -- #
    tfoutput=$(terraform -chdir=$PWD/tools/$tool/eks output -raw dashboard_ip | grep "http")
    if [ -n "$tfoutput" ]; then
      sed -i '' "/class=\"$tool\".*eks/ s|href=\"[^\"]*\"|href=\"$(terraform \
        -chdir=$PWD/tools/$tool/eks output -raw dashboard_ip)\"|" dashboards/index.html
    fi

    if [ $tool = "checkov" ]; then
      eval "$kubectl_update_kubeconfig" >/dev/null 2>&1
      echo "Wait for checkov ... "; sleep 90
      # todo: infinite loop
      kubectl logs job/checkov -n checkov > tools/checkov/checkov_output.txt
      sed -i '' -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g" \
        -e 's/FAILED/<span class="failed">FAILED<\/span>/g' \
        -e 's/PASSED/<span class="passed">PASSED<\/span>/g' \
        -e 's#\(Guide:\) \(https://[^ ]*\)#\1 <a href="\2">\2</a>#g' tools/checkov/checkov_output.txt
      sed '/<!-- INSERT KUBECTL OUTPUT HERE -->/r tools/checkov/checkov_output.txt' \
        tools/checkov/template.html > dashboards/eks/checkov.html
      sed -i '' "/class=\"checkov\".*eks/ s|href=\"[^\"]*\"|href=\"eks/checkov.html\"|" dashboards/index.html
    fi

    echo "$tool on EKS done"; sleep 2
    echo
  done <<< "$eks"
fi

# 2) GKE
if [ -n "$gke" ]; then
  echo "Deploying GKE cluster ..."; sleep 2
  if ! [ -e $GKE_TFVAR ]; then
    echo "gke.tfvars doesn't exist under deployment/vars."
    exit 1
  fi

  tfstate=$(terraform -chdir=$PWD/deployment/clusters/gke show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, GKE was already deployed."
  else
    terraform -chdir=$PWD/deployment/clusters/gke init
    terraform -chdir=$PWD/deployment/clusters/gke apply -var-file \
      $PWD/deployment/vars/gke.tfvars -auto-approve -compact-warnings
    if [ $? -ne 0 ]; then
      echo "Terraform failed, please examine the error above. Exiting 👋"
      exit 1
    fi
    echo "GKE done."; sleep 2
    echo
  fi

  kubectl_update_kubeconfig=$(terraform -chdir=$PWD/deployment/clusters/gke output -raw kubectl_update_kubeconfig)

  while IFS= read -r tool; do
    echo "Deploying $tool on GKE ..."; sleep 2
    tfstate=$(terraform -chdir=$PWD/tools/$tool/gke show)
    if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
    && [ "$tfstate" != "No state." ]; then
      echo -e " ➝ State file isn't empty, $tool on GKE was already deployed."
      continue
    else
      # -- deploy prometheus if needed -- #
      for item in "${prom[@]}"; do
        if [ $item = $tool ]; then
          tfstate=$(terraform -chdir=$PWD/deployment/addons/prometheus/gke show)
          if [ "$tfstate" = "The state file is empty. No resources are represented." ] \
          || [ "$tfstate" = "No state." ]; then
            terraform -chdir=$PWD/deployment/addons/prometheus/gke init
            terraform -chdir=$PWD/deployment/addons/prometheus/gke apply \
              -var-file $PWD/deployment/vars/gke.tfvars -auto-approve -compact-warnings

            if [ $? -ne 0 ]; then
              echo "Terraform failed, please examine the error above. Exiting 👋"
              exit 1
            fi

            # -- sed index.html with prom dashboard -- #
            sed -i '' "/class=\"$tool\".*gke/ s|href=\"[^\"]*\"|href=\"$(terraform \
            -chdir=$PWD/deployment/addons/prometheus/gke output -raw dashboard_ip)\"|" \
            dashboards/index.html
          fi
        fi
      done

      terraform -chdir=$PWD/tools/$tool/gke init
      terraform -chdir=$PWD/tools/$tool/gke apply -var-file \
        $PWD/deployment/vars/gke.tfvars -auto-approve -compact-warnings

      if [ $? -ne 0 ]; then
        echo "Terraform failed, please examine the error above. Exiting 👋"
        exit 1
      fi
    fi

    # -- sed index.html with private dashboard -- #
    tfoutput=$(terraform -chdir=$PWD/tools/$tool/gke output -raw dashboard_ip | grep "http")
    if [ -n "$tfoutput" ]; then
      sed -i '' "/class=\"$tool\".*gke/ s|href=\"[^\"]*\"|href=\"$(terraform \
        -chdir=$PWD/tools/$tool/gke output -raw dashboard_ip)\"|" dashboards/index.html
    fi

    if [ $tool = "checkov" ]; then
      eval "$kubectl_update_kubeconfig" >/dev/null 2>&1
      echo "Wait for checkov ... "; sleep 90
      # todo: infinite loop
      kubectl logs job/checkov -n checkov > tools/checkov/checkov_output.txt
      sed -i '' -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g" \
        -e 's/FAILED/<span class="failed">FAILED<\/span>/g' \
        -e 's/PASSED/<span class="passed">PASSED<\/span>/g' \
        -e 's#\(Guide:\) \(https://[^ ]*\)#\1 <a href="\2">\2</a>#g' tools/checkov/checkov_output.txt
      sed '/<!-- INSERT KUBECTL OUTPUT HERE -->/r tools/checkov/checkov_output.txt' \
        tools/checkov/template.html > dashboards/gke/checkov.html
      sed -i '' "/class=\"checkov\".*gke/ s|href=\"[^\"]*\"|href=\"gke/checkov.html\"|" dashboards/index.html
    fi

    echo "$tool on GKE done"; sleep 2
    echo
  done <<< "$gke"
fi


# 3) AKS
if [ -n "$aks" ]; then
  echo "Deploying AKS cluster ..."; sleep 2
  if ! [ -e $AKS_TFVAR ]; then
    echo "aks.tfvars doesn't exist under deployment/vars."
    exit 1
  fi

  tfstate=$(terraform -chdir=$PWD/deployment/clusters/aks show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, AKS was already deployed."
  else
    terraform -chdir=$PWD/deployment/clusters/aks init
    terraform -chdir=$PWD/deployment/clusters/aks apply -var-file \
      $PWD/deployment/vars/aks.tfvars -auto-approve -compact-warnings
    if [ $? -ne 0 ]; then
      echo "Terraform failed, please examine the error above. Exiting 👋"
      exit 1
    fi
    echo "AKS done."; sleep 2
    echo
  fi

  kubectl_update_kubeconfig=$(terraform -chdir=$PWD/deployment/clusters/aks output -raw kubectl_update_kubeconfig)

  while IFS= read -r tool; do
    echo "Deploying $tool on AKS ..."; sleep 2
    tfstate=$(terraform -chdir=$PWD/tools/$tool/aks show)
    if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
    && [ "$tfstate" != "No state." ]; then
      echo -e " ➝ State file isn't empty, $tool on AKS was already deployed."
      continue
    else
      # -- deploy prometheus if needed -- #
      for item in "${prom[@]}"; do
        if [ $item = $tool ]; then
          tfstate=$(terraform -chdir=$PWD/deployment/addons/prometheus/aks show)
          if [ "$tfstate" = "The state file is empty. No resources are represented." ] \
          || [ "$tfstate" = "No state." ]; then
            terraform -chdir=$PWD/deployment/addons/prometheus/aks init
            terraform -chdir=$PWD/deployment/addons/prometheus/aks apply \
              -var-file $PWD/deployment/vars/aks.tfvars -auto-approve -compact-warnings

            if [ $? -ne 0 ]; then
              echo "Terraform failed, please examine the error above. Exiting 👋"
              exit 1
            fi

            # -- sed index.html with prom dashboard -- #
            sed -i '' "/class=\"$tool\".*aks/ s|href=\"[^\"]*\"|href=\"$(terraform \
            -chdir=$PWD/deployment/addons/prometheus/aks output -raw dashboard_ip)\"|" \
            dashboards/index.html
          fi
        fi
      done

      terraform -chdir=$PWD/tools/$tool/aks init
      terraform -chdir=$PWD/tools/$tool/aks apply -var-file \
        $PWD/deployment/vars/aks.tfvars -auto-approve -compact-warnings

      if [ $? -ne 0 ]; then
        echo "Terraform failed, please examine the error above. Exiting 👋"
        exit 1
      fi
    fi

    # -- sed index.html with private dashboard -- #
    tfoutput=$(terraform -chdir=$PWD/tools/$tool/aks output -raw dashboard_ip | grep "http")
    if [ -n "$tfoutput" ]; then
      sed -i '' "/class=\"$tool\".*aks/ s|href=\"[^\"]*\"|href=\"$(terraform \
        -chdir=$PWD/tools/$tool/aks output -raw dashboard_ip)\"|" dashboards/index.html
    fi

    if [ $tool = "checkov" ]; then
      eval "$kubectl_update_kubeconfig" >/dev/null 2>&1
      echo "Wait for checkov ... "; sleep 90
      # todo: infinite loop
      kubectl logs job/checkov -n checkov > tools/checkov/checkov_output.txt
      sed -i '' -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g" \
        -e 's/FAILED/<span class="failed">FAILED<\/span>/g' \
        -e 's/PASSED/<span class="passed">PASSED<\/span>/g' \
        -e 's#\(Guide:\) \(https://[^ ]*\)#\1 <a href="\2">\2</a>#g' tools/checkov/checkov_output.txt
      sed '/<!-- INSERT KUBECTL OUTPUT HERE -->/r tools/checkov/checkov_output.txt' \
        tools/checkov/template.html > dashboards/aks/checkov.html
      sed -i '' "/class=\"checkov\".*aks/ s|href=\"[^\"]*\"|href=\"aks/checkov.html\"|" dashboards/index.html
    fi

    echo "$tool on AKS done"; sleep 2
    echo
  done <<< "$aks"
fi