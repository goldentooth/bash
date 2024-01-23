# GoldenTooth/Bash

Bash scripts for interacting with [GoldenTooth, my Pi Bramble/Cluster](https://github.com/goldentooth/).

It is probably most easily used with [`bpkg`](https://github.com/bpkg/bpkg).

```
Usage: goldentooth <subcommand> [arguments...]

Subcommands: 
             usage    Show usage information.
      ansible_task    Run a specified Ansible task.
        edit_vault    Edit the vault.
      autocomplete    Output autocomplete information.
      raspi_config    Run raspi-config.
   set_bash_prompt    Set Bash prompt.
      set_hostname    Set hostname.
          set_motd    Set MotD.
         setup_ssh    Setup SSH.
        setup_host    Setup everything but the cluster.
    create_cluster    Create the cluster.
```