#!/bin/bash

state_clusters=$(cat <<EOF
eks:
gke:
aks:
EOF
)

state_addons=$(cat <<EOF
prometheus:
  eks:
  gke:
  aks:
ssh:
  eks:
  gke:
  aks:
EOF
)

state_tools=$(cat <<EOF
kubesec:
kube-score:
polaris:
  eks:
  gke:
  aks:
kor:
  eks:
  gke:
  aks:
trivy-operator:
  eks:
  gke:
  aks:
checkov:
  eks:
  gke:
  aks:
EOF
)

# dependencies checks
terraform -version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Terraform can't be found."
  exit 1
fi

yq --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "yq can't be found."
  exit 1
fi

vendors=("eks" "gke" "aks")
# clusters
for cluster in deployment/clusters/*; do
  for vendor in "${vendors[@]}"; do
    if [ $(basename $cluster) = $vendor ]; then
      tfstate=$(terraform -chdir=$cluster show)
      if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
      && [ "$tfstate" != "No state." ]; then
        state_clusters=$(echo "$state_clusters" | yq ".$(basename $cluster) = \"active\"")
      fi
    fi
  done
done

# addons
for addon in deployment/addons/*; do
    for dir in $addon/*; do
      for vendor in "${vendors[@]}"; do
        if [[ $(basename $dir) == $vendor ]]; then
          tfstate=$(terraform -chdir=$dir show)
          if [[ "$tfstate" != "The state file is empty. No resources are represented." ]] \
          && [[ "$tfstate" != "No state." ]]; then
            state_addons=$(echo "$state_addons" | yq ".$(basename $addon).$vendor = \"active\"")
          fi
        fi
      done
    done
done

# static checks
# 1) kubesec
if [ -e "dashboards/kubesec.html" ]; then
  state_tools=$(echo "$state_tools" | yq '.kubesec = "active"')
fi
# 2) kube-score
if [ -e "dashboards/kube-score.html" ]; then
  state_tools=$(echo "$state_tools" | yq '.kube-score = "active"')
fi

# dynamic / terraform checks
for tool in tools/*; do
  for dir in $tool/*; do
    for vendor in "${vendors[@]}"; do
      if [ $(basename $dir) = $vendor ]; then
        tfstate=$(terraform -chdir=$dir show)
        if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
        && [ "$tfstate" != "No state." ]; then
          state_tools=$(echo "$state_tools" | yq ".$(basename $tool).$vendor = \"active\"")
        fi
      fi
    done
  done
done

echo "$state_clusters" | sed -e '/active/s/.*/\x1b[32m&\x1b[0m/' -e 's/active/🐋/g'
echo "---"
echo "$state_addons" | sed -e '/active/s/.*/\x1b[32m&\x1b[0m/' -e 's/active/🐋/g'
echo "---"
echo "$state_tools" | sed -e '/active/s/.*/\x1b[32m&\x1b[0m/' -e 's/active/🐋/g'