#!/bin/bash

terraform -version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Terraform can't be found."
  exit 1
fi

timeout=false

if [ $1 = "eks" ]; then
  tfstate=$(terraform -chdir=deployment/addons/ssh/eks show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, openssh-server on EKS was already deployed."
  else
    if ! [ -e "deployment/addons/ssh/id_rsa" ]; then
      ssh-keygen -t rsa -b 4096 -N "" -f deployment/addons/ssh/id_rsa
      chmod 600 deployment/addons/ssh/id_rsa
    fi

    sed -i '' "/name = \"PUBLIC_KEY\"/{n;s/\".*\"/\"$(cat deployment/addons/ssh/id_rsa.pub \
    | sed 's/\//\\\//g')\"/;}" deployment/addons/ssh/eks/main.tf

    terraform -chdir=deployment/addons/ssh/eks init
    terraform -chdir=deployment/addons/ssh/eks apply -var-file \
    $PWD/deployment/vars/eks.tfvars -auto-approve -compact-warnings
    timeout=true
  fi

  opensshserver=$(terraform -chdir=deployment/addons/ssh/eks output -raw ssh_server)
  if [ $timeout = true ]; then
    echo "Wait 90 seconds for the server to setup ..."
    sleep 90
  fi

  sleep 2; echo "socks5://localhost:9999 ..."
  eval "ssh -o StrictHostKeyChecking=no -i deployment/addons/ssh/id_rsa -p 2222 \
    linuxserver.io@$opensshserver -D 9999 -N" >/dev/null 2>&1

elif [ $1 = "gke" ]; then
  tfstate=$(terraform -chdir=deployment/addons/ssh/gke show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, openssh-server on GKE was already deployed."
  else
    if ! [ -e "deployment/addons/ssh/id_rsa" ]; then
      ssh-keygen -t rsa -b 4096 -N "" -f deployment/addons/ssh/id_rsa
      chmod 600 deployment/addons/ssh/id_rsa
    fi

    sed -i '' "/name = \"PUBLIC_KEY\"/{n;s/\".*\"/\"$(cat deployment/addons/ssh/id_rsa.pub \
    | sed 's/\//\\\//g')\"/;}" deployment/addons/ssh/gke/main.tf

    terraform -chdir=deployment/addons/ssh/gke init
    terraform -chdir=deployment/addons/ssh/gke apply -var-file \
    $PWD/deployment/vars/gke.tfvars -auto-approve -compact-warnings
    timeout=true
  fi

  opensshserver=$(terraform -chdir=deployment/addons/ssh/gke output -raw ssh_server)
  if [ $timeout = true ]; then
    echo "Wait 90 seconds for the server to setup ..."
    sleep 90
  fi

  sleep 2; echo "socks5://localhost:9999 ..."
  eval "ssh -o StrictHostKeyChecking=no -i deployment/addons/ssh/id_rsa -p 2222 \
    linuxserver.io@$opensshserver -D 9999 -N" >/dev/null 2>&1

elif [ $1 = "aks" ]; then
  tfstate=$(terraform -chdir=deployment/addons/ssh/aks show)
  if [ "$tfstate" != "The state file is empty. No resources are represented." ] \
  && [ "$tfstate" != "No state." ]; then
    echo -e " ➝ State file isn't empty, openssh-server on AKS was already deployed."
  else
    if ! [ -e "deployment/addons/ssh/id_rsa" ]; then
      ssh-keygen -t rsa -b 4096 -N "" -f deployment/addons/ssh/id_rsa
      chmod 600 deployment/addons/ssh/id_rsa
    fi

    sed -i '' "/name = \"PUBLIC_KEY\"/{n;s/\".*\"/\"$(cat deployment/addons/ssh/id_rsa.pub \
    | sed 's/\//\\\//g')\"/;}" deployment/addons/ssh/aks/main.tf

    terraform -chdir=deployment/addons/ssh/aks init
    terraform -chdir=deployment/addons/ssh/aks apply -var-file \
    $PWD/deployment/vars/aks.tfvars -auto-approve -compact-warnings
    timeout=true
  fi

  opensshserver=$(terraform -chdir=deployment/addons/ssh/aks output -raw ssh_server)
  if [ $timeout = true ]; then
    echo "Wait 90 seconds for the server to setup ..."
    sleep 90
  fi

  sleep 2; echo "socks5://localhost:9999 ..."
  eval "ssh -o StrictHostKeyChecking=no -i deployment/addons/ssh/id_rsa -p 2222 \
    linuxserver.io@$opensshserver -D 9999 -N" >/dev/null 2>&1
else
  echo "Wrong usage, read the docs."
fi