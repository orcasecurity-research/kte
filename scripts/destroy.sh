#!/bin/bash

# dependencies checks
terraform -version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Terraform can't be found."
  exit 1
fi

addons=false
clusters=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --addons)
      addons=true
      shift # Move to next argument
      ;;
     --clusters)
      clusters=true
      shift # Move to next argument
      ;;
  esac
done

echo "Destroy static checks"; sleep 2
# Static checks
# 1) kubesec
if [ -e "dashboards/kubesec.html" ]; then
  echo -n "Destroying kubesec ... "; sleep 2
  rm -rf dashboards/kubesec.html
  sed -i '' "/class=\"kubesec\"/ s|href=\"[^\"]*\"|href=\"#\"|" dashboards/index.html
  echo "done"; sleep 2
else
  echo -e " ➝ kubesec\t: Nothing to do"; sleep 2
fi
# 2) kube-score
if [ -e "dashboards/kube-score.html" ]; then
  echo -n "Destroying kube-score ... "; sleep 2
  rm -rf dashboards/kube-score.html
  sed -i '' "/class=\"kube-score\"/ s|href=\"[^\"]*\"|href=\"#\"|" dashboards/index.html
  echo "done"; sleep 2
else
  echo -e " ➝ kube-score\t: Nothing to do"; sleep 2
fi
echo

echo "Destroy IaC checks"; sleep 2
# Dynamic / Terraform checks
vendors=("eks" "gke" "aks")

# 1) Tools
echo "Destroy tools"; sleep 2
for tool in tools/*; do
  for dir in $tool/*; do
    for vendor in "${vendors[@]}"; do
      if [ $(basename $dir) = $vendor ]; then

        tfstate=$(terraform -chdir=tools/$(basename $tool)/$vendor show)
        if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
        && [ "$tfstate" != "No state." ]; then
          echo "Destroying $(basename $tool) on $vendor ..."; sleep 2
          terraform -chdir=tools/$(basename $tool)/$vendor destroy -var-file \
          $PWD/deployment/vars/$vendor.tfvars -auto-approve -compact-warnings

          if [ $? -ne 0 ]; then
            echo "Terraform failed, please examine the error above. Exiting 👋"
            exit 1
          fi

          echo "$(basename $tool) on $vendor done."
          sed -i '' "/class=\"$(basename $tool)\".*$vendor/ s|href=\"[^\"]*\"|href=\"#\"|" \
          dashboards/index.html
        fi

      fi
    done
  done
done

# 2) addons
if [[ $addons == true || $clusters == true ]]; then
  echo "Destroy addons"; sleep 2
  for addon in deployment/addons/*; do
      for dir in $addon/*; do
        for vendor in "${vendors[@]}"; do
          if [[ $(basename $dir) == $vendor ]]; then
            tfstate=$(terraform -chdir=$dir show)
            if [[ "$tfstate" != "The state file is empty. No resources are represented." ]] \
            && [[ "$tfstate" != "No state." ]]; then
              echo "Destroying $(basename $addon) on $vendor ..."; sleep 2
              terraform -chdir=$dir destroy -var-file \
              $PWD/deployment/vars/$vendor.tfvars -auto-approve -compact-warnings

              if [ $? -ne 0 ]; then
                echo "Terraform failed, please examine the error above. Exiting 👋"
                exit 1
              fi
            fi
          fi
        done
      done
  done
fi

# 3) clusters
if [[ $clusters == true ]]; then
  echo "Destroy clusters"; sleep 2
  for dir in deployment/clusters/*; do
    for vendor in "${vendors[@]}"; do
      if [ $(basename $dir) = $vendor ]; then

        tfstate=$(terraform -chdir=$dir show)
        if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
        && [ "$tfstate" != "No state." ]; then
          echo "Destroying $vendor ..."
          terraform -chdir=$dir destroy -var-file \
          $PWD/deployment/vars/$vendor.tfvars -auto-approve -compact-warnings

          if [ $? -ne 0 ]; then
            echo "Terraform failed, please examine the error above. Exiting 👋"
            exit 1
          fi

          echo "$vendor done."
        fi
      fi
    done
  done
fi