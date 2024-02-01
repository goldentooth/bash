# GoldenTooth/Bash

Bash scripts for interacting with [GoldenTooth, my Pi Bramble/Cluster](https://github.com/goldentooth/).

It is probably most easily used with [`bpkg`](https://github.com/bpkg/bpkg).

```
Usage: goldentooth <subcommand> [arguments...]

Subcommands:
              edit_vault    Edit the vault.
     setup_load_balancer    Setup the load balancer.
          setup_k8s_repo    Setup the Kubernetes repository.
           reset_cluster    Reset the cluster.
          create_cluster    Create the cluster.
                   usage    Show usage information.
         prepare_cluster    Setup everything but Kubernetes.
          setup_security    Apply some security settings.
            ansible_task    Run a specified Ansible task.
            set_hostname    Set hostname.
            setup_k8s_cp    Setup the Kubernetes control plane.
                 install    Install dependencies.
               configure    Configure the hosts (via e.g. `raspi-config`, `config.txt`).
         set_bash_prompt    Set Bash prompt.
            autocomplete    Output autocomplete information.
                    lint    Lint all roles.
                set_motd    Set MotD.
```