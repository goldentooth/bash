# Goldentooth/Bash

Bash scripts for interacting with [Goldentooth, my Pi Bramble/Cluster](https://github.com/goldentooth/).

## Installation

### With bpkg

Install using [`bpkg`](https://github.com/bpkg/bpkg):

```bash
bpkg install goldentooth/bash
```

### Manual Installation

```bash
git clone https://github.com/goldentooth/bash.git
cd bash
make install
```

**IMPORTANT**: After making any changes to the `goldentooth.sh` script, you must run `make install` again to update the system-wide command.

## Usage

The `goldentooth` command provides a unified interface for managing your Pi cluster through Ansible playbooks and ad-hoc commands.

```
$ goldentooth
Usage: goldentooth <subcommand> [arguments...]

Subcommands:
            autocomplete Enable bash autocompletion.
                 install Install Ansible dependencies.
                    lint Lint all roles.
                    ping Ping all hosts.
                  uptime Get uptime for all hosts.
                 command Run an arbitrary command on all hosts.
              edit_vault Edit the vault.
        ansible_playbook Run a specified Ansible playbook.
                   usage Display usage information.
                   adhoc Run Some Ad-Hoc Ansible Tasks.
               apt_envoy Setup Envoy package repositories for Apt.
             apt_grafana Setup Grafana Apt Repo.
           apt_hashicorp Setup HashiCorp Apt Repo.
                 apt_k8s Setup Kubernetes package repositories for Apt.
           apt_smallstep Setup Smallstep Apt Repo.
              apt_vector Setup Vector Apt Repo.
    bootstrap_cluster_ca Bootstrap cluster Certificate Authority (CA).
    bootstrap_consul_acl Bootstrap Consul ACL.
           bootstrap_k8s Bootstrap Kubernetes cluster with kubeadm.
                 cleanup Perform various cleanup tasks.
       configure_cluster Configure the hosts in the cluster.
         init_cluster_ca Initialize Root and Intermediate CAs.
    install_argo_cd_apps Install Argo CD applications.
         install_argo_cd Install Argo CD on Kubernetes cluster.
          install_consul Install HashiCorp Consul.
           install_envoy Install Envoy.
            install_helm Install Helm on Kubernetes cluster.
    install_k8s_packages Install Kubernetes packages.
           install_nomad Install HashiCorp Nomad.
         install_step_ca Install Smallstep packages.
        install_step_cli Install Smallstep CLI package.
           install_vault Install HashiCorp Vault.
                     msg Evaluate a message on a host or group.
               reset_k8s Reset Kubernetes cluster with kubeadm.
     rotate_consul_certs Rotate Consul TLS certificates.
      rotate_nomad_certs Rotate Nomad TLS certificates.
      rotate_vault_certs Rotate Vault TLS certificates.
            setup_consul Setup Consul.
            setup_docker Setup Docker.
             setup_envoy Setup Envoy.
           setup_grafana Setup Grafana.
     setup_load_balancer Setup the load balancer.
              setup_loki Setup Loki.
        setup_networking Setup networking.
       setup_nfs_exports Setup NFS exports.
        setup_nfs_mounts Setup NFS mounts.
    setup_node_homepages Setup the node homepages.
             setup_nomad Setup Nomad.
        setup_prometheus Setup Prometheus.
               setup_ray Setup Ray.
             setup_slurm Setup Slurm (legacy - use modular commands below).
        setup_slurm_core Setup Slurm core configuration only (fast).
         setup_hpc_software Setup HPC software stack (slow, idempotent).
             setup_lmod Setup Lmod environment module system.
     setup_slurm_modules Setup module files for HPC software.
             setup_vault Setup HashiCorp Consul.
            setup_vector Setup Vector.
                shutdown Cleanly shut down the hosts in the cluster.
  uninstall_k8s_packages Uninstall Kubernetes packages.
             upgrade_k8s Upgrade Kubernetes.
                     var Evaluate a variable on a host or group.
          zap_cluster_ca Delete the old cluster Certificate Authority.
```

## Common Commands

### Basic Operations
```bash
# Check if all hosts are reachable
goldentooth ping all

# Get uptime for all hosts
goldentooth uptime all

# Run arbitrary commands on specific hosts
goldentooth command node1,node2 "free -h"

# Debug variables on hosts
goldentooth debug_var node1 "ansible_hostname"
```

### Cluster Management
```bash
# Install dependencies
goldentooth install

# Lint Ansible roles
goldentooth lint

# Bootstrap Kubernetes cluster
goldentooth bootstrap_k8s

# Setup various services
goldentooth setup_docker
goldentooth setup_consul
goldentooth setup_nomad
```

### Slurm HPC Setup (Modular Approach)
```bash
# Fast Slurm core setup (essential configuration only)
goldentooth setup_slurm_core

# Setup Lmod environment module system
goldentooth setup_lmod

# Install HPC software stack (slow, but highly idempotent)
goldentooth setup_hpc_software

# Create module files for installed software
goldentooth setup_slurm_modules

# Legacy: Full Slurm setup (slow, not recommended)
goldentooth setup_slurm
```

### Interactive Mode
```bash
# Start an interactive Ansible console
goldentooth console all

# Edit encrypted vault
goldentooth edit_vault
```

## Environment Variables

- `GOLDENTOOTH_ANSIBLE_PATH`: Path to the Ansible directory (default: `~/Projects/goldentooth/ansible`)

## Requirements

- Bash 4.0+
- Ansible
- Access to your Goldentooth cluster inventory

## License

See [LICENSE](LICENSE) for details.
