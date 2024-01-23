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

# Run raspi-config.
function goldentooth:raspi_config() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.raspi_config' "${args}";
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

# Set up SSH.
function goldentooth:setup_ssh() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.setup_ssh' "${args}";
  popd > /dev/null;
}

# Create the cluster.
function goldentooth:create_cluster() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOSTNAME|GROUP>"}";
  local host_expression="${1}";
  local args="${@:2}";
  pushd "${ansible_path}" > /dev/null;
  goldentooth:ansible_role "${host_expression}" 'goldentooth.create_cluster' -e 'ansible_user=root' "${args}";
  popd > /dev/null;
}

# Show usage information.
function goldentooth:usage() {
  local subcommand_width='18';
  local subcommand_column="%${subcommand_width}s    %s\n";
  echo 'Usage: goldentooth <subcommand> [arguments...]';
  echo '';
  echo 'Subcommands: ';
  printf "${subcommand_column}" 'usage' 'Show usage information.';
  printf "${subcommand_column}" 'ansible_task' 'Run a specified Ansible task.';
  printf "${subcommand_column}" 'edit_vault' 'Edit the vault.';
  printf "${subcommand_column}" 'autocomplete' 'Output autocomplete information.';
  printf "${subcommand_column}" 'raspi_config' 'Run raspi-config.';
  printf "${subcommand_column}" 'set_bash_prompt' 'Set Bash prompt.';
  printf "${subcommand_column}" 'set_hostname' 'Set hostname.';
  printf "${subcommand_column}" 'set_motd' 'Set MotD.';
  printf "${subcommand_column}" 'setup_ssh' 'Set up SSH.';
  printf "${subcommand_column}" 'create_cluster' 'Create the cluster.';
  echo '';
}

general_subcommands=(
  'usage'
  'ansible_task'
  'edit_vault'
  'autocomplete'
)

# Print autocomplete script.
function hellholt:autocomplete() {
  local old_ifs="${IFS}";
  IFS=\ ;
  local all_subcommands=(
    "$(echo "${general_subcommands[*]}")"
  )
  local subcommands_string="$(echo "${all_subcommands[*]}")";
  echo complete -W "'"${subcommands_string}"'" hellholt;
  IFS="${old_ifs}";
}

# Primary function.
function goldentooth() {
  local subcommand="${1}";
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES';
  export K8S_AUTH_KUBECONFIG='~/.kube/config';
  shift;
  if type "goldentooth:${subcommand%:*}" > /dev/null 2>&1; then
    host_expression="${1}";
    shift;
    "goldentooth:${subcommand%:*}" "${host_expression}" "${@:1}";
  else
    goldentooth:usage;
  fi;
}

goldentooth "${@}";
exit $?;
