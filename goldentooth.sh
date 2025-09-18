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
venv_path="${ansible_path}/.venv";

# Load inventory groups for SSH operations
if [ -f "/usr/local/bin/goldentooth-inventory.sh" ]; then
  source "/usr/local/bin/goldentooth-inventory.sh"
fi

# Setup Ansible virtual environment (run once).
function goldentooth:setup_venv() {
  echo "Setting up Ansible virtual environment..."

  # Create virtual environment
  python3 -m venv "${venv_path}"

  # Activate and install packages
  source "${venv_path}/bin/activate"
  pip install --upgrade pip ansible kubernetes

  echo "Virtual environment setup complete at ${venv_path}"
}

# Activate Ansible virtual environment.
function goldentooth:activate_venv() {
  if [ ! -d "${venv_path}" ]; then
    echo "Ansible virtual environment not found. Run 'goldentooth setup_venv' first."
    return 1
  fi
  source "${venv_path}/bin/activate"
}

# Helper function to enter ansible directory with venv activated.
function goldentooth:enter_ansible() {
  pushd "${ansible_path}" > /dev/null
  goldentooth:activate_venv || return 1
}

# Install Ansible dependencies.
function goldentooth:install() {
  goldentooth:enter_ansible || return 1;
  ansible-galaxy install -r requirements.yml;
  popd > /dev/null;
}

# Agent - run the Goldentooth Agent command.
function goldentooth:agent() {
  : "${1?"Usage: ${FUNCNAME[0]} <COMMAND> [ARGS]..."}";
  local command="${1}";
  shift;
  goldentooth:enter_ansible || return 1;
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
  goldentooth:enter_ansible || return 1;
  ansible-console "${targets}" "${@}";
  popd > /dev/null;
}

# Run cluster health tests.
function goldentooth:test() {
  local test_suite="${1:-all}";
  shift;
  local test_path="${ansible_path}";

  # Check if ansible directory exists
  if [[ ! -d "${test_path}" ]]; then
    echo "Ansible directory not found at ${test_path}";
    return 1;
  fi;

  pushd "${test_path}" > /dev/null;
  goldentooth:activate_venv || return 1;

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
  goldentooth:enter_ansible || return 1;
  ansible "${targets}" -m ping;
  popd > /dev/null;
}

# Get uptime for all hosts.
function goldentooth:uptime() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)>"}";
  local targets="${1}";
  goldentooth:enter_ansible || return 1;
  ansible "${targets}" -a "uptime";
  popd > /dev/null;
}



# Run a raw command as root user (bypasses shell escaping).
function goldentooth:raw_root() {
  : "${1?"Usage: ${FUNCNAME[0]} <TARGET(S)> <COMMAND>"}";
  local targets="${1}";
  shift;
  local command_expression="${*}";
  goldentooth:enter_ansible || return 1;
  ansible "${targets}" -m raw -a "${command_expression}" -u root;
  popd > /dev/null;
}


# Lint all roles.
function goldentooth:lint() {
  goldentooth:enter_ansible || return 1;
  ansible-lint;
  popd > /dev/null;
}

# Edit the vault.
function goldentooth:edit_vault() {
  goldentooth:enter_ansible || return 1;
  ansible-vault edit ./inventory/group_vars/all/vault;
  popd > /dev/null;
}

# View the vault contents.
function goldentooth:view_vault() {
  goldentooth:enter_ansible || return 1;
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password;
  popd > /dev/null;
}

# Get a specific value from the vault.
function goldentooth:get_vault() {
  : "${1?"Usage: ${FUNCNAME[0]} <VAULT_PATH> (e.g., secret_vault.consul.mgmt_token)"}";
  local vault_path="${1}";
  goldentooth:enter_ansible || return 1;
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password | yq ".${vault_path}";
  popd > /dev/null;
}

# Set a specific value in the vault.
function goldentooth:set_vault() {
  : "${2?"Usage: ${FUNCNAME[0]} <VAULT_PATH> <VALUE> (e.g., secret_vault.consul.mgmt_token \"new-token-value\")"}";
  local vault_path="${1}";
  local new_value="${2}";
  goldentooth:enter_ansible || return 1;
  # Create a temporary file with the updated vault contents
  local temp_vault=$(mktemp);
  ansible-vault view ./inventory/group_vars/all/vault --vault-password-file ~/.goldentooth_vault_password | yq ".${vault_path} = \"${new_value}\"" > "${temp_vault}";
  # Encrypt the updated contents back to the vault
  ansible-vault encrypt "${temp_vault}" --vault-password-file ~/.goldentooth_vault_password --output ./inventory/group_vars/all/vault;
  rm "${temp_vault}";
  popd > /dev/null;
}



# Execute SSH command on resolved hosts
function goldentooth:exec() {
  local hosts="$1"
  local command="$2"
  local parallel_mode="${3:-false}"

  # SSH options for clean output (disable pseudo-terminal to suppress MOTD)
  local ssh_opts="-T -o StrictHostKeyChecking=no -o LogLevel=ERROR -q"

  # Convert hosts string to array
  read -ra host_array <<< "$hosts"

  if [[ "${#host_array[@]}" -eq 1 ]]; then
    # Single host - direct SSH
    local host="${host_array[0]}"
    ssh ${ssh_opts} "root@${host}" "$command"
  elif [[ "${#host_array[@]}" -gt 1 ]]; then
    if goldentooth:check_parallel && [[ "$parallel_mode" == "true" ]]; then
      # Use GNU parallel for multiple hosts
      printf '%s\n' "${host_array[@]}" | \
        parallel -j0 --tag "ssh ${ssh_opts} root@{} '$command'"
    else
      # Sequential execution
      for host in "${host_array[@]}"; do
        echo "${host}:"
        ssh ${ssh_opts} "root@${host}" "$command"
      done
    fi
  else
    echo "No hosts resolved from target" >&2
    return 1
  fi
}

# Interactive shell for cluster nodes (SSH-based)
function goldentooth:shell() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOST_EXPRESSION> (e.g., bettley, all, consul_server)"}";
  local target="${1}";

  # Resolve target to actual hosts
  local hosts
  if type goldentooth:resolve_hosts >/dev/null 2>&1; then
    hosts=$(goldentooth:resolve_hosts "$target")
  else
    hosts="$target"  # Fallback to direct host name
  fi

  # Convert to array and check count
  read -ra host_array <<< "$hosts"
  local host_count="${#host_array[@]}"

  if [[ "$host_count" -eq 1 ]]; then
    local host="${host_array[0]}"
    echo "Connecting to ${host}..."

    # Direct SSH session (interactive, bypass profile to skip MOTD)
    ssh -t -o StrictHostKeyChecking=no -o LogLevel=ERROR -q "root@${host}" "bash --noprofile"

  elif [[ "$host_count" -gt 1 ]]; then
    echo "Interactive shell for ${host_count} hosts: ${host_array[*]}"
    echo "Commands will execute on all ${host_count} hosts. Type 'exit' to return."
    echo "WARNING: Broadcast mode - commands run on ALL selected hosts!"
    echo

    while true; do
      read -p "[${target}:${host_count}]$ " -e command

      # Exit condition
      [[ "$command" == "exit" ]] && break

      # Skip empty commands
      [[ -z "$command" ]] && continue

      goldentooth:exec "$hosts" "$command" "true"
    done
  else
    echo "No hosts resolved from target: ${target}" >&2
    return 1
  fi
}

# Pipe input to cluster nodes (SSH-based)
function goldentooth:pipe() {
  : "${1?"Usage: echo 'commands' | ${FUNCNAME[0]} <HOST_EXPRESSION>"}";
  local target="${1}";

  # Resolve target to actual hosts
  local hosts
  if type goldentooth:resolve_hosts >/dev/null 2>&1; then
    hosts=$(goldentooth:resolve_hosts "$target")
  else
    hosts="$target"
  fi

  read -ra host_array <<< "$hosts"

  # Read from stdin and execute each line
  while IFS= read -r command; do
    [[ -z "$command" ]] && continue
    [[ "$command" =~ ^[[:space:]]*# ]] && continue  # Skip comments

    goldentooth:ssh_exec "$hosts" "$command" "true"  # Use parallel for efficiency
  done
}

# Copy files to/from cluster nodes (scp wrapper)
function goldentooth:cp() {
  : "${1?"Usage: ${FUNCNAME[0]} <source> <destination> (supports node:path syntax)"}";
  : "${2?"Usage: ${FUNCNAME[0]} <source> <destination> (supports node:path syntax)"}";
  local source="${1}";
  local destination="${2}";

  # Parse node:path format
  if [[ "$source" =~ ^([^:]+):(.+)$ ]]; then
    local source_node="${BASH_REMATCH[1]}";
    local source_path="${BASH_REMATCH[2]}";
    scp "root@${source_node}:${source_path}" "${destination}";
  elif [[ "$destination" =~ ^([^:]+):(.+)$ ]]; then
    local dest_node="${BASH_REMATCH[1]}";
    local dest_path="${BASH_REMATCH[2]}";
    scp "${source}" "root@${dest_node}:${dest_path}";
  else
    echo "Error: Use node:path syntax (e.g., bettley:/opt/file.txt)" >&2;
    echo "Examples:" >&2;
    echo "  goldentooth cp local-file.txt bettley:/tmp/" >&2;
    echo "  goldentooth cp allyrion:/var/log/app.log ./logs/" >&2;
    return 1;
  fi
}

# Execute batch commands from a script file (SSH-based)
function goldentooth:batch() {
  : "${1?"Usage: ${FUNCNAME[0]} <script-file> [target=all]"}";
  local script_file="${1}";
  local target="${2:-all}";

  if [[ ! -f "$script_file" ]]; then
    echo "Script file not found: $script_file" >&2;
    return 1;
  fi

  # Resolve target to actual hosts
  local hosts
  if type goldentooth:resolve_hosts >/dev/null 2>&1; then
    hosts=$(goldentooth:resolve_hosts "$target")
  else
    hosts="$target"
  fi

  # Read script file and execute commands
  while IFS= read -r command || [[ -n "$command" ]]; do
    # Skip empty lines and comments
    [[ -z "$command" ]] && continue
    [[ "$command" =~ ^[[:space:]]*# ]] && continue

    goldentooth:ssh_exec "$hosts" "$command" "true"  # Use parallel
  done < "$script_file"
}

# Here-document execution for multi-line commands (SSH-based)
function goldentooth:heredoc() {
  : "${1?"Usage: ${FUNCNAME[0]} <HOST_EXPRESSION> <<'EOF' ... EOF"}";
  local target="${1}";

  # Resolve target to actual hosts
  local hosts
  if type goldentooth:resolve_hosts >/dev/null 2>&1; then
    hosts=$(goldentooth:resolve_hosts "$target")
  else
    hosts="$target"
  fi

  # Create a temporary script from stdin
  local temp_script=$(mktemp);
  cat > "$temp_script"

  # Execute the temporary script
  goldentooth:batch "$temp_script" "$target"

  # Clean up
  rm -f "$temp_script"
}

# Run a specified Ansible playbook.
function goldentooth:ansible_playbook() {
  : "${1?"Usage: ${FUNCNAME[0]} <PLAYBOOK> ..."}";
  local playbook_expression="${1}";
  shift;
  goldentooth:enter_ansible || return 1;
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
  ["exec"]="Execute SSH command on resolved hosts."
  ["raw_root"]="Run a raw command as root user (bypasses shell escaping)."
  ["edit_vault"]="Edit the vault."
  ["view_vault"]="View the vault contents."
  ["get_vault"]="Get a specific value from the vault."
  ["set_vault"]="Set a specific value in the vault."
  ["agent"]="Run the Goldentooth Agent command."
  ["debug_var"]="Debug a variable on the specified hosts."
  ["debug_msg"]="Debug a message on the specified hosts."
  ["console"]="Start an interactive Ansible console."
  ["ansible_playbook"]="Run a specified Ansible playbook."
  ["test"]="Run cluster health tests."
  ["usage"]="Display usage information."
  ["shell"]="Start interactive shell for cluster nodes."
  ["set_motd"]="Set node-specific MOTD with ASCII art."
  ["pipe"]="Pipe commands from stdin to cluster nodes."
  ["cp"]="Copy files to/from cluster nodes (scp wrapper)."
  ["batch"]="Execute batch commands from a script file."
  ["heredoc"]="Execute here-document (multi-line) commands."
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
  goldentooth:enter_ansible || return 1;
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
  goldentooth:enter_ansible || return 1;
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
