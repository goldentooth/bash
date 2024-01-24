#!/usr/bin/env bash

ansible_path="${HELLHOLT_ANSIBLE_PATH:-${HOME}/Projects/cluster}";

# Edit the vault.
function goldentooth:edit_vault() {
  pushd "${ansible_path}" > /dev/null;
  ansible-vault edit ./inventory/group_vars/all/vault;
  popd > /dev/null;
}

# Run a specified Ansible playbook.
function goldentooth:ansible_playbook() {
  : "${2?"Usage: ${FUNCNAME[0]} <PLAYBOOK>"}";
  local playbook_expression="${1}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook "${playbook_expression}";
  popd > /dev/null;
}

# Run a specified Ansible role.
function goldentooth:ansible_role() {
  : "${2?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP> <ROLE> <TASKFILE>"}";
  local host_expression="${1}";
  local role_name="${2}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook ${@:3} /dev/stdin <<END
---
- hosts: $host_expression
  roles:
    - '$role_name'
END
  popd > /dev/null;
}

# Run a specified Ansible task.
function goldentooth:ansible_task() {
  : "${3?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP> <ROLE> <TASKFILE>"}";
  local host_expression="${1}";
  local role_name="${2}";
  local task_file="${3}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook ${@:4} /dev/stdin <<END
---
- hosts: $host_expression
  remote_user: 'root'
  tasks:

  - name: 'Execute $role_name:$task_file'
    ansible.builtin.include_role:
      name: '$role_name'
      tasks_from: '$task_file'
END
  popd > /dev/null;
}

# Run raspi-config and edit boot.txt.
function goldentooth:configure() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.configure' "${args}";
  popd > /dev/null;
}

# Set the Bash Prompt on a specified node or group.
function goldentooth:set_bash_prompt() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.set_bash_prompt' "${args}";
  popd > /dev/null;
}

# Set the hostname on a specified node or group.
function goldentooth:set_hostname() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.set_hostname' "${args}";
  popd > /dev/null;
}

# Set the MotD on a specified node or group.
function goldentooth:set_motd() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.set_motd' "${args}";
  popd > /dev/null;
}

# Setup security settings.
function goldentooth:setup_security() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.setup_security' "${args}";
  popd > /dev/null;
}

# Create the cluster.
function goldentooth:create_cluster() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.create_cluster' "${args}";
  popd > /dev/null;
}

# Prepare the cluster but don't actually setup Kubernetes.
function goldentooth:prepare_cluster() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.prepare_cluster' "${args}";
  popd > /dev/null;
}

# Reset the cluster.
function goldentooth:reset_cluster() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.reset_cluster' "${args}";
  popd > /dev/null;
}

# Define associative array for subcommands and their descriptions.
#
# Associative arrays are a feature of Bash 4.0. If you're using a Mac, you'll
# need to install Bash 4.0+ with Homebrew.
declare -A subcommands=(
  [usage]='Show usage information.'
  [ansible_task]='Run a specified Ansible task.'
  [edit_vault]='Edit the vault.'
  [autocomplete]='Output autocomplete information.'
  [configure]='Configure the hosts (via e.g. `raspi-config`, `boot.txt`).'
  [set_bash_prompt]='Set Bash prompt.'
  [set_hostname]='Set hostname.'
  [set_motd]='Set MotD.'
  [setup_security]='Apply some security settings.'
  [prepare_cluster]='Setup everything but Kubernetes.'
  [create_cluster]='Create the cluster.'
  [reset_cluster]='Reset the cluster.'
)

# Show usage information.
function goldentooth:usage() {
  local subcommand_width='18';
  local subcommand_column="%${subcommand_width}s    %s\n";
  echo 'Usage: goldentooth <subcommand> [arguments...]';
  echo '';
  echo 'Subcommands: ';
  for cmd in "${!subcommands[@]}"; do
    printf "$subcommand_column" "$cmd" "${subcommands[$cmd]}"
  done
  echo '';
}

# Print autocomplete script.
function goldentooth:autocomplete() {
  local subcommands_string="${!subcommands[@]}"
  echo "complete -W '$subcommands_string' goldentooth"
}

# Primary function.
function goldentooth() {
  local subcommand="${1:-usage}";
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES';
  export K8S_AUTH_KUBECONFIG='~/.kube/config';
  shift;
  if type "goldentooth:${subcommand%:*}" > /dev/null 2>&1; then
    host_expression="${1:-all}";
    shift;
    "goldentooth:${subcommand%:*}" "${host_expression}" "${@:1}";
  else
    goldentooth:usage;
  fi;
}

goldentooth "${@}";
exit $?;
