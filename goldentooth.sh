#!/usr/bin/env bash

ansible_path="${HELLHOLT_ANSIBLE_PATH:-${HOME}/Projects/cluster}";

# Install Ansible dependencies.
function goldentooth:install() {
  pushd "${ansible_path}" > /dev/null;
  ansible-galaxy install -r requirements.yml;
  pushd kubespray > /dev/null;
  pip3 install -r requirements.txt;
  popd > /dev/null;
  popd > /dev/null;
}

# Lint all roles.
function goldentooth:lint() {
  pushd "${ansible_path}" > /dev/null;
  ansible-lint;
  popd > /dev/null;
}

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
  ansible-playbook "playbooks/${playbook_expression}.yaml";
  popd > /dev/null;
}

# Display usage information.
function goldentooth:usage() {
  local width=24;
  echo 'Usage: goldentooth <subcommand> [arguments...]';
  echo '';
  echo 'Subcommands:';
  printf "%${width}s %s\n" "autocomplete" "Enable bash autocompletion.";
  printf "%${width}s %s\n" "install" "Install Ansible dependencies.";
  printf "%${width}s %s\n" "lint" "Lint all roles.";
  printf "%${width}s %s\n" "edit_vault" "Edit the vault.";
  printf "%${width}s %s\n" "ansible_playbook" "Run a specified Ansible playbook.";
  printf "%${width}s %s\n" "usage" "Display usage information.";
  pushd "${ansible_path}" > /dev/null;
  for playbook in playbooks/*.yaml; do
    playbook_name="$(basename "${playbook}" '.yaml')";
    first_line="$(head -n 1 "${playbook}")";
    description="$(echo "${first_line}" | sed -n 's/^# Description: \(.*\)/\1/p')";
    if [[ -n $description ]]; then
      printf "%${width}s %s\n" "${playbook_name}" "${description}";
    fi
  done;
  popd > /dev/null;
  echo '';
}

# Print autocomplete script.
function goldentooth:autocomplete() {
  local subcommands_string="";
  pushd "${ansible_path}" > /dev/null;
  for playbook in playbooks/*.yaml; do
    playbook_name="$(basename "${playbook}" .yaml)";
    subcommands_string="${subcommands_string} ${playbook_name}";
  done;
  popd > /dev/null;
  echo "complete -W 'autocomplete usage $subcommands_string' goldentooth";
}

# Primary function.
function goldentooth() {
  local subcommand="${1:-usage}";
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY='YES';
  export K8S_AUTH_KUBECONFIG='~/.kube/config';
  if type "goldentooth:${subcommand%:*}" > /dev/null 2>&1; then
    host_expression="${1:-all}";
    shift;
    "goldentooth:${subcommand%:*}" "${host_expression}" "${@:1}";
  else
    goldentooth:ansible_playbook "${subcommand}" "${@:1}";
  fi;
}

goldentooth "${@}";
exit $?;
