#!/usr/bin/env bash
#
# Goldentooth CLI - Unified interface for cluster operations
#
# IMPORTANT: After making changes to this script, you MUST run `make install`
# from the bash/ directory to install the updated version system-wide.
#
# Usage: goldentooth <command> [args...]
# Example: goldentooth test slurm
#          goldentooth setup_consul all
#          goldentooth ping all
#

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

# Run cluster health tests.
function goldentooth:test() {
  local test_suite="${1:-all}";
  shift;
  local test_path="${ansible_path}/tests";
  
  # Check if test directory exists
  if [[ ! -d "${test_path}" ]]; then
    echo "Test directory not found at ${test_path}";
    return 1;
  fi;
  
  pushd "${test_path}" > /dev/null;
  
  # Set vault password file if it exists
  if [[ -f ~/.goldentooth_vault_password ]]; then
    export ANSIBLE_VAULT_PASSWORD_FILE=~/.goldentooth_vault_password;
  fi;
  
  # Dynamically discover available test suites
  local available_suites=()
  for playbook in playbooks/test_*.yaml; do
    if [[ -f "$playbook" ]]; then
      local suite_name=$(basename "$playbook" .yaml | sed 's/^test_//')
      available_suites+=("$suite_name")
    fi
  done
  
  case "${test_suite}" in
    quick)
      echo "Running quick health checks...";
      ansible-playbook "playbooks/test_all.yaml" --tags "system" "${@}";
      ;;
    *)
      # Check if the test suite exists
      local suite_found=false
      for suite in "${available_suites[@]}"; do
        if [[ "$suite" == "$test_suite" ]]; then
          suite_found=true
          break
        fi
      done
      
      if [[ "$suite_found" == true ]]; then
        echo "Running ${test_suite} tests...";
        ansible-playbook "playbooks/test_${test_suite}.yaml" "${@}";
      else
        echo "Unknown test suite: ${test_suite}";
        echo "Available test suites: $(IFS=', '; echo "${available_suites[*]}"), quick";
        popd > /dev/null;
        return 1;
      fi
      ;;
  esac;
  
  local result=$?;
  popd > /dev/null;
  return $result;
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
  ansible-playbook playbooks/command.yaml --limit="${targets}" --extra-vars "command_to_run='${command_expression}'";
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

# Run a raw command as root user (bypasses shell escaping).
function goldentooth:raw_root() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)> <COMMAND>"}";
  local targets="${1}";
  shift;
  local command_expression="${*}";
  pushd "${ansible_path}" > /dev/null;
  ansible "${targets}" -m raw -a "${command_expression}" -u root;
  popd > /dev/null;
}

# Run an arbitrary command as root user.
function goldentooth:command_root() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)> <COMMAND>"}";
  local targets="${1}";
  shift;
  local command_expression="${*}";
  pushd "${ansible_path}" > /dev/null;
  ansible-playbook playbooks/command.yaml --limit="${targets}" --extra-vars "command_to_run='${command_expression}'" -u root;
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

# View the vault contents.
function goldentooth:view_vault() {
  pushd "${ansible_path}" > /dev/null;
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password;
  popd > /dev/null;
}

# Get a specific value from the vault.
function goldentooth:get_vault() {
  : "${1?"Usage: ${FUNCNAME[0]} <VAULT_PATH> (e.g., secret_vault.consul.mgmt_token)"}";
  local vault_path="${1}";
  pushd "${ansible_path}" > /dev/null;
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password | yq ".${vault_path}";
  popd > /dev/null;
}

# Set a specific value in the vault.
function goldentooth:set_vault() {
  : "${2?"Usage: ${FUNCNAME[0]} <VAULT_PATH> <VALUE> (e.g., secret_vault.consul.mgmt_token \"new-token-value\")"}";
  local vault_path="${1}";
  local new_value="${2}";
  pushd "${ansible_path}" > /dev/null;
  # Create a temporary file with the updated vault contents
  local temp_vault=$(mktemp);
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password | yq ".${vault_path} = \"${new_value}\"" > "${temp_vault}";
  # Encrypt the updated contents back to the vault
  ansible-vault encrypt "${temp_vault}" --vault-password-file ~/.goldentooth_vault_password --output ./inventory/group_vars/all/vault;
  rm "${temp_vault}";
  popd > /dev/null;
}

# Get MCP authentication token via Authelia OIDC flow.
function goldentooth:mcp_auth() {
  local mcp_endpoint="https://mcp.services.goldentooth.net";
  
  echo "Getting MCP authentication token...";
  echo "";
  
  # Check for required tools
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed.";
    return 1;
  fi;
  
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed.";
    return 1;
  fi;
  
  # Get authorization URL
  echo "Step 1: Getting authorization URL...";
  local auth_response=$(curl -s -X POST "${mcp_endpoint}/auth/authorize" \
    -H "Content-Type: application/json" \
    -d '{}' -k);
  
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to connect to MCP server. Is it running?";
    return 1;
  fi;
  
  local auth_url=$(echo "${auth_response}" | jq -r '.authorization_url // empty');
  
  if [[ -z "${auth_url}" || "${auth_url}" == "null" ]]; then
    echo "Error: Failed to get authorization URL.";
    echo "Response: ${auth_response}";
    return 1;
  fi;
  
  # Display authorization URL
  echo "";
  echo "Step 2: Open this URL in your browser and log in:";
  echo "${auth_url}";
  echo "";
  echo "After logging in, you'll be redirected to a URL that looks like:";
  echo "https://mcp.services.goldentooth.net/callback?code=AUTHORIZATION_CODE";
  echo "";
  
  # Get authorization code from user
  read -p "Copy the 'code' parameter from the redirect URL and paste it here: " auth_code;
  
  if [[ -z "${auth_code}" ]]; then
    echo "Error: No authorization code provided.";
    return 1;
  fi;
  
  # Exchange code for token
  echo "";
  echo "Step 3: Exchanging authorization code for access token...";
  local token_response=$(curl -s -X POST "${mcp_endpoint}/auth/token" \
    -H "Content-Type: application/json" \
    -d "{\"code\": \"${auth_code}\"}" -k);
  
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to exchange authorization code for token.";
    return 1;
  fi;
  
  local access_token=$(echo "${token_response}" | jq -r '.access_token // empty');
  local expires_in=$(echo "${token_response}" | jq -r '.expires_in // empty');
  
  if [[ -z "${access_token}" || "${access_token}" == "null" ]]; then
    echo "Error: Failed to get access token.";
    echo "Response: ${token_response}";
    return 1;
  fi;
  
  # Display results
  echo "";
  echo "✅ Success! Your JWT access token:";
  echo "${access_token}";
  echo "";
  
  if [[ -n "${expires_in}" && "${expires_in}" != "null" ]]; then
    echo "Token expires in: ${expires_in} seconds";
    echo "";
  fi;
  
  echo "To use with Claude Code:";
  echo "";
  echo "claude mcp add --transport http goldentooth_mcp ${mcp_endpoint}/mcp/request --header \"Authorization: Bearer ${access_token}\"";
  echo "";
  echo "If you need to remove and re-add the server:";
  echo "claude mcp remove goldentooth_mcp";
  echo "claude mcp add --transport http goldentooth_mcp ${mcp_endpoint}/mcp/request --header \"Authorization: Bearer ${access_token}\"";
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
  ["command_root"]="Run an arbitrary command as root user."
  ["raw_root"]="Run a raw command as root user (bypasses shell escaping)."
  ["edit_vault"]="Edit the vault."
  ["view_vault"]="View the vault contents."
  ["get_vault"]="Get a specific value from the vault."
  ["set_vault"]="Set a specific value in the vault."
  ["mcp_auth"]="Get MCP authentication token via Authelia OIDC flow."
  ["agent"]="Run the Goldentooth Agent command."
  ["debug_var"]="Debug a variable on the specified hosts."
  ["debug_msg"]="Debug a message on the specified hosts."
  ["console"]="Start an interactive Ansible console."
  ["ansible_playbook"]="Run a specified Ansible playbook."
  ["test"]="Run cluster health tests."
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
    # Check if the function is test, which doesn't need a host expression
    if [[ "${subcommand%:*}" == "test" ]]; then
      "goldentooth:${subcommand%:*}" "${@}";
    else
      host_expression="${1:-all}";
      shift;
      "goldentooth:${subcommand%:*}" "${host_expression}" "${@:1}";
    fi;
  else
    playbook_expression="${subcommand}";
    shift;
    goldentooth:ansible_playbook "${playbook_expression}" "${@}";
  fi;
}

goldentooth "${@}";
exit $?;
