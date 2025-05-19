# Goldentooth/Bash

Bash scripts for interacting with [Goldentooth, my Pi Bramble/Cluster](https://github.com/goldentooth/).

It is probably most easily used with [`bpkg`](https://github.com/bpkg/bpkg).

```
Usage: goldentooth <subcommand> [arguments...]

Subcommands:
            autocomplete Enable bash autocompletion.
                 install Install Ansible dependencies.
                    lint Lint all roles.
              edit_vault Edit the vault.
        ansible_playbook Run a specified Ansible playbook.
                   usage Display usage information.
          create_cluster Create a Kubernetes cluster.
         prepare_cluster Prepare the nodes in the cluster.
           reset_cluster Reset the Kubernetes cluster.
     setup_load_balancer Setup the load balancer.
         upgrade_cluster Upgrade Kubernetes cluster.
```
