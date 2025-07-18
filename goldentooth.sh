#!/usr/bin/env bash

ansible_path="${GOLDENTOOTH_ANSIBLE_PATH:-${HOME}/Projects/goldentooth/ansible}";

# Install Ansible dependencies.
function goldentooth:install() {
  pushd "${ansible_path}" > /dev/null;
  ansible-galaxy install -r requirements.yml;
  popd > /dev/null;
}

# Agent - run the Goldentooth Agent command.
function goldentooth:agent() {
  : "${1?"Usage: ${FUNCNAME[0]} <COMMAND> [ARGS]..."}";
  local command="${1}";
  shift;
  pushd "${ansible_path}" > /dev/null;
  # Check and see if uvx is installed. If not, install it.
  if ! command -v uvx &> /dev/null; then
    echo "uvx not found, installing...";
    curl -LsSf https://astral.sh/uv/install.sh | sh;
  fi;
  # Run the command using uvx.
  uvx --from git+https://github.com/goldentooth/agent goldentooth-agent "$@";
  popd > /dev/null;
}

# Ansible Console - start an interactive Ansible console.
function goldentooth:console() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)> [ARGS]..."}";
  local targets="${1}";
  shift;
  pushd "${ansible_path}" > /dev/null;
  ansible-console "${targets}" "${@}";
  popd > /dev/null;
}

# Debug a variable on the specified hosts.
function goldentooth:debug_var() {
  : "${2?"Usage: ${FUNCNAME[0]} <TARGET(S)> <EXPRESSION>"}";
  local targets="${1}";
  shift;
  local expression="${@}";
  goldentooth:ansible_playbook 'var' --limit="${targets}" --extra-vars "var=${expression}";
}

# Debug a message on the specified hosts.
function goldentooth:debug_msg() {
  : "${2?"Usage: ${FUNCNAME[0]} <TARGET(S)> <EXPRESSION>"}";
  local targets="${1}";
  shift;
  local expression="${@}";
  goldentooth:ansible_playbook 'msg' --limit="${targets}" --extra-vars="msg=\"${expression}\"";
}

# Ping all hosts.
function goldentooth:ping() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)>"}";
  local targets="${1}";
  pushd "${ansible_path}" > /dev/null;
  ansible "${targets}" -m ping;
  popd > /dev/null;
}

# Get uptime for all hosts.
function goldentooth:uptime() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)>"}";
  local targets="${1}";
  pushd "${ansible_path}" > /dev/null;
  ansible "${targets}" -a "uptime";
  popd > /dev/null;
}

# Run an arbitrary command on all hosts.
function goldentooth:command() {
  : "${2?"Usage: ${FUNCNAME[0]} <TARGET(S)> <COMMAND>"}";
  local targets="${1}";
  shift;
  local command_expression="${*}";
  pushd "${ansible_path}" > /dev/null;
  ansible "${targets}" -m shell -a "${command_expression}";
  popd > /dev/null;
}

# Run a raw command on all hosts (bypasses shell escaping).
function goldentooth:raw() {
  : "${2?"Usage: ${FUNCNAME[0]} <TARGET(S)> <COMMAND>"}";
  local targets="${1}";
  shift;
  local command_expression="${*}";
  pushd "${ansible_path}" > /dev/null;
  ansible "${targets}" -m raw -a "${command_expression}";
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
  : "${1?"Usage: ${FUNCNAME[0]} <PLAYBOOK> ..."}";
  local playbook_expression="${1}";
  shift;
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook "playbooks/${playbook_expression}.yaml" "${@}";
  popd > /dev/null;
}

# Built-in command definitions
declare -A GOLDENTOOTH_COMMANDS=(
  ["autocomplete"]="Enable bash autocompletion."
  ["install"]="Install Ansible dependencies."
  ["lint"]="Lint all roles."
  ["ping"]="Ping all hosts."
  ["uptime"]="Get uptime for all hosts."
  ["command"]="Run an arbitrary command on all hosts."
  ["raw"]="Run a raw command on all hosts (bypasses shell escaping)."
  ["edit_vault"]="Edit the vault."
  ["agent"]="Run the Goldentooth Agent command."
  ["debug_var"]="Debug a variable on the specified hosts."
  ["debug_msg"]="Debug a message on the specified hosts."
  ["console"]="Start an interactive Ansible console."
  ["ansible_playbook"]="Run a specified Ansible playbook."
  ["usage"]="Display usage information."
)

# Display usage information.
function goldentooth:usage() {
  local width=24;
  echo 'Usage: goldentooth <subcommand> [arguments...]';
  echo '';
  echo 'Subcommands:';
  
  # Display built-in commands
  for command in "${!GOLDENTOOTH_COMMANDS[@]}"; do
    printf "%${width}s %s\n" "${command}" "${GOLDENTOOTH_COMMANDS[${command}]}";
  done | sort;
  
  # Display playbook commands
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
    shift;
    host_expression="${1:-all}";
    shift;
    "goldentooth:${subcommand%:*}" "${host_expression}" "${@:1}";
  else
    playbook_expression="${subcommand}";
    shift;
    goldentooth:ansible_playbook "${playbook_expression}" "${@}";
  fi;
}

goldentooth "${@}";
exit $?;
