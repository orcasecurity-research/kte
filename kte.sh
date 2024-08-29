#!/bin/bash

# Function to display usage information
function display_help {
    echo "Usage: ./kte.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  apply                  Execute the apply script"
    echo "  state                  Execute the state script"
    echo "  destroy [OPTIONS]      Execute the destroy script with options"
    echo "  tunnel [OPTIONS]       Execute the tunnel script with options"
    echo "  ai [OPTIONS]           Execute the ai script with options"
    echo
    echo "Options:"
    echo "  -h, --help    Display this help manual and exit."
    echo
    echo "Examples:"
    echo "  ./kte.sh apply"
}

function display_destroy_help {
    echo "Usage: ./kte.sh destroy [options]"
    echo ""
    echo "Options:"
    echo "  --addons      Destroy addons."
    echo "  --clusters    Destroy clusters."
    echo "  -h, --help    Display this help manual and exit."
    echo ""
    echo "Examples:"
    echo "  ./kte.sh destroy"
    echo "  ./kte.sh destroy --clusters"
}

function display_tunnel_help {
    echo "Usage: ./kte.sh tunnel [options]"
    echo ""
    echo "Options:"
    echo "  eks    tunnel through eks."
    echo "  gke    tunnel through gke."
    echo "  aks    tunnel through aks."
    echo "  -h, --help    Display this help manual and exit."
    echo ""
    echo "Examples:"
    echo "  ./kte.sh tunnel eks"
}

function display_ai_help {
    echo "Usage: ./kte.sh ai [options]"
    echo ""
    echo "Options:"
    echo "  setup <vendor>  setup AI and RAG infrastructure for a specific vendor."
    echo "  prompt          start a prompt and ask questions about your k8s findings."
    echo "  -h, --help    Display this help manual and exit."
    echo ""
    echo "Examples:"
    echo "  ./kte.sh ai setup eks"
    echo "  ./kte.sh ai prompt"
}

if [ $# -eq 0 ]; then
    display_help
    exit 1
fi

destroy_clusters=false
destroy_addons=false

case "$1" in
    apply )
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          * )
            echo "Invalid option: $1"
            display_help
            exit 1
            ;;
        esac
      done
      ./scripts/apply.sh
      ;;
    state )
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          * )
            echo "Invalid option: $1"
            display_help
            exit 1
            ;;
        esac
      done
      ./scripts/state.sh
      ;;
    destroy )
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --clusters )
            destroy_clusters=true
            shift
            ;;
          --addons )
            destroy_addons=true
            shift
            ;;
          -h | --help )
            display_destroy_help
            exit 0
            ;;
          * )
            echo "Invalid option: $1"
            display_destroy_help
            exit 1
            ;;
        esac
      done
      if [[ $destroy_clusters == true && $destroy_addons == true ]]; then
        ./scripts/destroy.sh --addons --clusters
      elif [[ $destroy_addons == true ]]; then
        ./scripts/destroy.sh --addons
      elif [[ $destroy_clusters == true ]]; then
        ./scripts/destroy.sh --clusters
      else
        ./scripts/destroy.sh
      fi
      ;;
    tunnel )
      shift
      case "$1" in
        eks )
          ./scripts/tunnel.sh eks
          ;;
        gke )
          ./scripts/tunnel.sh gke
          ;;
        aks )
          ./scripts/tunnel.sh aks
          ;;
        -h | --help )
          display_tunnel_help
          exit 0
          ;;
        * )
          echo "Invalid option: $1"
          display_tunnel_help
          exit 1
          ;;
      esac
      ;;
    ai )
      shift
      case "$1" in
        setup )
          shift
          case "$1" in
            eks )
              export PYTHONPATH=$PWD; poetry run python ai/main.py setup eks
              ;;
            gke )
              export PYTHONPATH=$PWD; poetry run python ai/main.py setup gke
              ;;
            aks )
              export PYTHONPATH=$PWD; poetry run python ai/main.py setup aks
              ;;
            * )
              echo "Invalid option: $1"
              display_ai_help
              exit 1
              ;;
          esac
          ;;
        prompt )
          export PYTHONPATH=$PWD; poetry run python ai/main.py prompt
          ;;
        -h | --help )
          display_ai_help
          exit 0
          ;;
        * )
          echo "Invalid option: $1"
          display_ai_help
          exit 1
          ;;
      esac
      ;;
    -h | --help )
      display_help
      exit 0
      ;;
    * )
      echo "Invalid option: $1"
      display_help
      exit 1
      ;;
esac