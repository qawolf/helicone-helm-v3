#!/bin/bash

# kubeseal-string.sh - Convert plaintext strings to kubesealed format
# Usage: ./kubeseal-string.sh [options] <key> <value>
# 
# Options:
#   -n, --namespace <namespace>     Target namespace (default: helicone)
#   -s, --secret-name <name>        Secret name (default: temp-secret)
#   -c, --controller-ns <namespace> Controller namespace (default: kube-system)
#   --controller-name <name>        Controller name (default: sealed-secrets-controller)
#   -f, --format <format>           Output format: yaml|json (default: yaml)
#   -o, --output-only               Output only the encrypted value
#   -h, --help                      Show this help message
#
# Examples:
#   ./kubeseal-string.sh mykey myvalue
#   ./kubeseal-string.sh -n production -s myapp-secrets database_password "super-secret-password"
#   ./kubeseal-string.sh -o mykey myvalue  # Output only encrypted value

set -euo pipefail

# Default values
NAMESPACE="helicone"
SECRET_NAME="temp-secret"
CONTROLLER_NAMESPACE="kube-system"
CONTROLLER_NAME="sealed-secrets-controller"
FORMAT="yaml"
OUTPUT_ONLY=false
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Help function
show_help() {
    cat << EOF
kubeseal-string.sh - Convert plaintext strings to kubesealed format

USAGE:
    $0 [options] <key> <value>

OPTIONS:
    -n, --namespace <namespace>     Target namespace (default: helicone)
    -s, --secret-name <name>        Secret name (default: temp-secret)
    -c, --controller-ns <namespace> Controller namespace (default: kube-system)
    --controller-name <name>        Controller name (default: sealed-secrets-controller)
    -f, --format <format>           Output format: yaml|json (default: yaml)
    -o, --output-only               Output only the encrypted value
    -h, --help                      Show this help message

EXAMPLES:
    # Basic usage
    $0 mykey myvalue

    # Specify namespace and secret name
    $0 -n production -s myapp-secrets database_password "super-secret-password"

    # Output only the encrypted value (useful for scripts)
    $0 -o mykey myvalue

    # Multiple key-value pairs (interactive mode)
    $0 --interactive

REQUIREMENTS:
    - kubeseal CLI must be installed
    - kubectl must be configured with cluster access
    - sealed-secrets controller must be installed in the cluster

EOF
}

# Check if kubeseal is installed
check_kubeseal() {
    if ! command -v kubeseal &> /dev/null; then
        echo -e "${RED}Error: kubeseal CLI is not installed${NC}" >&2
        echo "Install it from: https://github.com/bitnami-labs/sealed-secrets/releases" >&2
        exit 1
    fi
}

# Check if kubectl is configured
check_kubectl() {
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}" >&2
        exit 1
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -s|--secret-name)
                SECRET_NAME="$2"
                shift 2
                ;;
            -c|--controller-ns)
                CONTROLLER_NAMESPACE="$2"
                shift 2
                ;;
            --controller-name)
                CONTROLLER_NAME="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                if [[ "$FORMAT" != "yaml" && "$FORMAT" != "json" ]]; then
                    echo -e "${RED}Error: Format must be 'yaml' or 'json'${NC}" >&2
                    exit 1
                fi
                shift 2
                ;;
            -o|--output-only)
                OUTPUT_ONLY=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}" >&2
                show_help
                exit 1
                ;;
            *)
                # Positional arguments
                if [[ -z "${KEY:-}" ]]; then
                    KEY="$1"
                elif [[ -z "${VALUE:-}" ]]; then
                    VALUE="$1"
                else
                    echo -e "${RED}Error: Too many positional arguments${NC}" >&2
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Interactive mode for multiple key-value pairs
interactive_mode() {
    echo -e "${BLUE}Interactive mode: Enter key-value pairs (empty key to finish)${NC}"
    
    declare -A secrets
    while true; do
        echo -n "Enter key (or press Enter to finish): "
        read -r key
        if [[ -z "$key" ]]; then
            break
        fi
        
        echo -n "Enter value for '$key': "
        read -rs value
        echo
        
        secrets["$key"]="$value"
    done
    
    if [[ ${#secrets[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No secrets entered${NC}"
        exit 0
    fi
    
    # Create secret YAML with all key-value pairs
    create_multi_secret_yaml secrets
}

# Create secret YAML file
create_secret_yaml() {
    local key="$1"
    local value="$2"
    local secret_file="$TEMP_DIR/secret.yaml"
    
    cat > "$secret_file" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  $key: "$value"
EOF
    
    echo "$secret_file"
}

# Create secret YAML with multiple key-value pairs
create_multi_secret_yaml() {
    local -n secrets_ref=$1
    local secret_file="$TEMP_DIR/secret.yaml"
    
    cat > "$secret_file" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
EOF
    
    for key in "${!secrets_ref[@]}"; do
        echo "  $key: \"${secrets_ref[$key]}\"" >> "$secret_file"
    done
    
    echo "$secret_file"
}

# Generate sealed secret
generate_sealed_secret() {
    local secret_file="$1"
    local sealed_secret_file="$TEMP_DIR/sealed-secret.yaml"
    
    kubeseal \
        --format="$FORMAT" \
        --namespace="$NAMESPACE" \
        --controller-namespace="$CONTROLLER_NAMESPACE" \
        --controller-name="$CONTROLLER_NAME" \
        < "$secret_file" > "$sealed_secret_file"
    
    echo "$sealed_secret_file"
}

# Extract encrypted value from sealed secret
extract_encrypted_value() {
    local sealed_secret_file="$1"
    local key="$2"
    
    if [[ "$FORMAT" == "yaml" ]]; then
        # Use grep and awk to extract the encrypted value from YAML
        local encrypted_value
        encrypted_value=$(grep -A 1000 "encryptedData:" "$sealed_secret_file" | grep "^[[:space:]]*${key}:" | awk -F': ' '{print $2}' | tr -d '"' | head -n 1)
        
        if [[ -z "$encrypted_value" || "$encrypted_value" == "null" ]]; then
            echo -e "${RED}Error: Could not extract encrypted value for key '$key'${NC}" >&2
            echo "Available keys:" >&2
            grep -A 1000 "encryptedData:" "$sealed_secret_file" | grep "^[[:space:]]*[^[:space:]]*:" | awk -F':' '{print $1}' | sed 's/^[[:space:]]*/- /' >&2
            exit 1
        fi
        
        echo "$encrypted_value"
    else
        jq -r ".spec.encryptedData.\"$key\"" "$sealed_secret_file" 2>/dev/null || {
            echo -e "${RED}Error: Could not extract encrypted value for key '$key'${NC}" >&2
            echo "Available keys:" >&2
            jq -r '.spec.encryptedData | keys[]' "$sealed_secret_file" >&2
            exit 1
        }
    fi
}

# Main function
main() {
    parse_args "$@"
    
    # Check prerequisites
    check_kubeseal
    check_kubectl
    
    # Handle interactive mode
    if [[ "${INTERACTIVE:-false}" == "true" ]]; then
        interactive_mode
        return
    fi
    
    # Validate required arguments
    if [[ -z "${KEY:-}" ]] || [[ -z "${VALUE:-}" ]]; then
        echo -e "${RED}Error: Both key and value are required${NC}" >&2
        show_help
        exit 1
    fi
    
    echo -e "${BLUE}Generating sealed secret...${NC}"
    echo "Namespace: $NAMESPACE"
    echo "Secret name: $SECRET_NAME"
    echo "Key: $KEY"
    echo "Controller: $CONTROLLER_NAME (namespace: $CONTROLLER_NAMESPACE)"
    echo
    
    # Create secret YAML
    secret_file=$(create_secret_yaml "$KEY" "$VALUE")
    
    # Generate sealed secret
    sealed_secret_file=$(generate_sealed_secret "$secret_file")
    
    if [[ "$OUTPUT_ONLY" == "true" ]]; then
        # Output only the encrypted value
        extract_encrypted_value "$sealed_secret_file" "$KEY"
    else
        # Output the full sealed secret
        echo -e "${GREEN}Generated SealedSecret:${NC}"
        echo
        cat "$sealed_secret_file"
        echo
        echo -e "${YELLOW}Encrypted value for key '$KEY':${NC}"
        extract_encrypted_value "$sealed_secret_file" "$KEY"
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 