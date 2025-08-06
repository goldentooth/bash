#!/usr/bin/env python3
"""
Parse Ansible inventory file and generate bash variables for goldentooth CLI.
This allows SSH-based operations to use Ansible group definitions.
"""

import sys
import yaml
import json
from pathlib import Path

def parse_inventory(inventory_path):
    """Parse YAML inventory file and extract groups and hosts."""
    try:
        with open(inventory_path, 'r') as f:
            inventory = yaml.safe_load(f)
    except Exception as e:
        print(f"Error reading inventory: {e}", file=sys.stderr)
        return {}
    
    groups = {}
    all_hosts = set()
    
    def extract_hosts(section, prefix=""):
        """Recursively extract hosts from inventory sections."""
        if not isinstance(section, dict):
            return set()
            
        hosts = set()
        
        # Direct hosts
        if 'hosts' in section:
            if isinstance(section['hosts'], dict):
                hosts.update(section['hosts'].keys())
            elif isinstance(section['hosts'], list):
                hosts.update(section['hosts'])
        
        # Child groups
        if 'children' in section:
            for child_name, child_section in section['children'].items():
                child_hosts = extract_hosts(child_section, f"{prefix}{child_name}.")
                hosts.update(child_hosts)
                if child_hosts:  # Only add non-empty groups
                    groups[child_name] = sorted(child_hosts)
        
        return hosts
    
    # Process the inventory
    if 'all' in inventory and 'children' in inventory['all']:
        for group_name, group_section in inventory['all']['children'].items():
            group_hosts = extract_hosts(group_section)
            if group_hosts:  # Only add non-empty groups
                groups[group_name] = sorted(group_hosts)
                all_hosts.update(group_hosts)
    
    # Add special groups
    groups['all'] = sorted(all_hosts) if all_hosts else []
    
    return groups

def generate_bash_variables(groups):
    """Generate bash functions for group resolution (compatible with older bash)."""
    lines = [
        "#!/bin/bash",
        "# Auto-generated inventory variables for goldentooth CLI",
        "# Generated from Ansible inventory",
        "",
        "# Function to resolve host expression to actual hosts",
        "function goldentooth:resolve_hosts() {",
        "  local expression=\"${1}\"",
        "  ",
        "  case \"$expression\" in",
    ]
    
    # Generate case statements for each group
    for group_name, hosts in sorted(groups.items()):
        if hosts:  # Only include non-empty groups
            hosts_str = " ".join(hosts)
            lines.append(f'    "{group_name}")')
            lines.append(f'      echo "{hosts_str}"')
            lines.append(f'      ;;')
    
    lines.extend([
        "    *)",
        "      # Assume it's a direct host name",
        "      echo \"$expression\"",
        "      ;;",
        "  esac",
        "}",
        "",
        "# Function to list all available groups",
        "function goldentooth:list_groups() {",
        "  echo \"Available groups:\"",
    ])
    
    # Add group listing
    for group_name, hosts in sorted(groups.items()):
        if hosts:
            lines.append(f'  echo "  {group_name}: {len(hosts)} hosts"')
    
    lines.extend([
        "}",
        "",
        "# Function to check if GNU parallel is available", 
        "function goldentooth:check_parallel() {",
        "  command -v parallel >/dev/null 2>&1",
        "}",
        "",
        "# Function to check if a target is a known group",
        "function goldentooth:is_group() {",
        "  local target=\"$1\"",
        "  case \"$target\" in",
    ])
    
    # Add group validation
    for group_name in sorted(groups.keys()):
        if groups[group_name]:
            lines.append(f'    "{group_name}") return 0 ;;')
    
    lines.extend([
        "    *) return 1 ;;",
        "  esac",
        "}",
    ])
    
    return "\n".join(lines)

def main():
    if len(sys.argv) != 3:
        print("Usage: parse-inventory.py <inventory_file> <output_file>")
        sys.exit(1)
    
    inventory_path = sys.argv[1]
    output_path = sys.argv[2]
    
    if not Path(inventory_path).exists():
        print(f"Error: Inventory file {inventory_path} not found")
        sys.exit(1)
    
    groups = parse_inventory(inventory_path)
    bash_code = generate_bash_variables(groups)
    
    with open(output_path, 'w') as f:
        f.write(bash_code)
    
    print(f"Generated inventory variables in {output_path}")
    print(f"Found {len(groups)} groups with {len(groups.get('all', []))} total hosts")

if __name__ == "__main__":
    main()