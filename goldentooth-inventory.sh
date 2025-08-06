#!/bin/bash
# Auto-generated inventory variables for goldentooth CLI
# Generated from Ansible inventory

# Function to resolve host expression to actual hosts
function goldentooth:resolve_hosts() {
  local expression="${1}"
  
  case "$expression" in
    "all")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "all_nodes")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "all_non_pis")
      echo "velaryon"
      ;;
    "all_pi_4b")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps"
      ;;
    "all_pi_4b_4gb")
      echo "karstark lipps"
      ;;
    "all_pi_4b_8gb")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast"
      ;;
    "all_pi_5")
      echo "manderly norcross oakheart payne"
      ;;
    "all_pis")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne"
      ;;
    "authelia")
      echo "jast"
      ;;
    "consul")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "consul_client")
      echo "allyrion erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "consul_server")
      echo "bettley cargyll dalt"
      ;;
    "distributed_llama")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne"
      ;;
    "distributed_llama_root")
      echo "manderly"
      ;;
    "distributed_llama_worker")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps norcross oakheart payne"
      ;;
    "docker")
      echo "allyrion"
      ;;
    "envoy")
      echo "allyrion"
      ;;
    "grafana")
      echo "gardener"
      ;;
    "haproxy")
      echo "allyrion"
      ;;
    "k8s_cluster")
      echo "bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "k8s_control_plane")
      echo "bettley cargyll dalt"
      ;;
    "k8s_worker")
      echo "erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "k8s_worker_gpu")
      echo "velaryon"
      ;;
    "loki")
      echo "inchfield"
      ;;
    "mcp_server")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "nfs_server")
      echo "allyrion velaryon"
      ;;
    "nomad")
      echo "bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "nomad_client")
      echo "erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "nomad_client_gpu")
      echo "velaryon"
      ;;
    "nomad_server")
      echo "bettley cargyll dalt"
      ;;
    "prometheus")
      echo "allyrion"
      ;;
    "ray")
      echo "allyrion bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "ray_head")
      echo "erenford"
      ;;
    "ray_worker")
      echo "allyrion bettley cargyll dalt fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne velaryon"
      ;;
    "ray_worker_gpu")
      echo "velaryon"
      ;;
    "seaweedfs")
      echo "manderly norcross oakheart payne"
      ;;
    "slurm")
      echo "bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne"
      ;;
    "slurm_compute")
      echo "bettley cargyll dalt erenford fenn gardener harlton inchfield jast karstark lipps manderly norcross oakheart payne"
      ;;
    "slurm_controller")
      echo "bettley cargyll dalt"
      ;;
    "step_ca")
      echo "jast"
      ;;
    "vault")
      echo "bettley cargyll dalt"
      ;;
    "zfs")
      echo "allyrion erenford gardener"
      ;;
    *)
      # Assume it's a direct host name
      echo "$expression"
      ;;
  esac
}

# Function to list all available groups
function goldentooth:list_groups() {
  echo "Available groups:"
  echo "  all: 17 hosts"
  echo "  all_nodes: 17 hosts"
  echo "  all_non_pis: 1 hosts"
  echo "  all_pi_4b: 12 hosts"
  echo "  all_pi_4b_4gb: 2 hosts"
  echo "  all_pi_4b_8gb: 10 hosts"
  echo "  all_pi_5: 4 hosts"
  echo "  all_pis: 16 hosts"
  echo "  authelia: 1 hosts"
  echo "  consul: 17 hosts"
  echo "  consul_client: 14 hosts"
  echo "  consul_server: 3 hosts"
  echo "  distributed_llama: 16 hosts"
  echo "  distributed_llama_root: 1 hosts"
  echo "  distributed_llama_worker: 15 hosts"
  echo "  docker: 1 hosts"
  echo "  envoy: 1 hosts"
  echo "  grafana: 1 hosts"
  echo "  haproxy: 1 hosts"
  echo "  k8s_cluster: 16 hosts"
  echo "  k8s_control_plane: 3 hosts"
  echo "  k8s_worker: 13 hosts"
  echo "  k8s_worker_gpu: 1 hosts"
  echo "  loki: 1 hosts"
  echo "  mcp_server: 17 hosts"
  echo "  nfs_server: 2 hosts"
  echo "  nomad: 16 hosts"
  echo "  nomad_client: 13 hosts"
  echo "  nomad_client_gpu: 1 hosts"
  echo "  nomad_server: 3 hosts"
  echo "  prometheus: 1 hosts"
  echo "  ray: 17 hosts"
  echo "  ray_head: 1 hosts"
  echo "  ray_worker: 16 hosts"
  echo "  ray_worker_gpu: 1 hosts"
  echo "  seaweedfs: 4 hosts"
  echo "  slurm: 15 hosts"
  echo "  slurm_compute: 15 hosts"
  echo "  slurm_controller: 3 hosts"
  echo "  step_ca: 1 hosts"
  echo "  vault: 3 hosts"
  echo "  zfs: 3 hosts"
}

# Function to check if GNU parallel is available
function goldentooth:check_parallel() {
  command -v parallel >/dev/null 2>&1
}

# Function to check if a target is a known group
function goldentooth:is_group() {
  local target="$1"
  case "$target" in
    "all") return 0 ;;
    "all_nodes") return 0 ;;
    "all_non_pis") return 0 ;;
    "all_pi_4b") return 0 ;;
    "all_pi_4b_4gb") return 0 ;;
    "all_pi_4b_8gb") return 0 ;;
    "all_pi_5") return 0 ;;
    "all_pis") return 0 ;;
    "authelia") return 0 ;;
    "consul") return 0 ;;
    "consul_client") return 0 ;;
    "consul_server") return 0 ;;
    "distributed_llama") return 0 ;;
    "distributed_llama_root") return 0 ;;
    "distributed_llama_worker") return 0 ;;
    "docker") return 0 ;;
    "envoy") return 0 ;;
    "grafana") return 0 ;;
    "haproxy") return 0 ;;
    "k8s_cluster") return 0 ;;
    "k8s_control_plane") return 0 ;;
    "k8s_worker") return 0 ;;
    "k8s_worker_gpu") return 0 ;;
    "loki") return 0 ;;
    "mcp_server") return 0 ;;
    "nfs_server") return 0 ;;
    "nomad") return 0 ;;
    "nomad_client") return 0 ;;
    "nomad_client_gpu") return 0 ;;
    "nomad_server") return 0 ;;
    "prometheus") return 0 ;;
    "ray") return 0 ;;
    "ray_head") return 0 ;;
    "ray_worker") return 0 ;;
    "ray_worker_gpu") return 0 ;;
    "seaweedfs") return 0 ;;
    "slurm") return 0 ;;
    "slurm_compute") return 0 ;;
    "slurm_controller") return 0 ;;
    "step_ca") return 0 ;;
    "vault") return 0 ;;
    "zfs") return 0 ;;
    *) return 1 ;;
  esac
}