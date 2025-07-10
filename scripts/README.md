# Kubeseal String Utility

This directory contains utilities for working with sealed secrets in the Helicone Helm charts.

## generate-sealed-secrets.sh

A bash script that converts plaintext strings to kubesealed format, compatible with the sealed-secrets controller configuration used in this project.

### Prerequisites

1. **kubeseal CLI** - Install from [sealed-secrets releases](https://github.com/bitnami-labs/sealed-secrets/releases)

   ```bash
   # macOS
   brew install kubeseal

   # Linux
   KUBESEAL_VERSION="0.26.0"
   curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
   tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
   sudo install -m 755 kubeseal /usr/local/bin/kubeseal
   ```

2. **kubectl** - Must be configured with access to your Kubernetes cluster
3. **sealed-secrets controller** - Must be installed in your cluster (handled by helicone-infrastructure chart)

### Usage

#### Basic Usage

```bash
# Convert a single key-value pair
./scripts/generate-sealed-secrets.sh mykey myvalue

# Specify namespace (default: helicone)
./scripts/generate-sealed-secrets.sh -n production database_password "super-secret-password"

# Get only the encrypted value (useful for scripts)
./scripts/generate-sealed-secrets.sh -o postgres-password "my-secret-password"
```

#### Advanced Usage

```bash
# Use custom secret name and controller settings
./scripts/generate-sealed-secrets.sh \
  -n production \
  -s myapp-secrets \
  --controller-name sealed-secrets-controller \
  --controller-ns kube-system \
  database_url "postgresql://user:pass@host:5432/db"

# Output in JSON format
./scripts/generate-sealed-secrets.sh -f json mykey myvalue

# Interactive mode for multiple secrets
./scripts/generate-sealed-secrets.sh --interactive
```

### Options

| Option                | Description                           | Default                     |
| --------------------- | ------------------------------------- | --------------------------- |
| `-n, --namespace`     | Target namespace                      | `helicone`                  |
| `-s, --secret-name`   | Secret name                           | `temp-secret`               |
| `-c, --controller-ns` | Controller namespace                  | `kube-system`               |
| `--controller-name`   | Controller name                       | `sealed-secrets-controller` |
| `-f, --format`        | Output format (yaml/json)             | `yaml`                      |
| `-o, --output-only`   | Output only encrypted value           | `false`                     |
| `--interactive`       | Interactive mode for multiple secrets | -                           |
| `-h, --help`          | Show help message                     | -                           |

### Examples for Helicone Secrets

Based on the sealed-secrets template, here are examples for common Helicone secrets:

```bash
# Database password
./scripts/generate-sealed-secrets.sh -n helicone postgres-password "your-postgres-password"

# S3 credentials
./scripts/generate-sealed-secrets.sh -n helicone access_key "your-s3-access-key"
./scripts/generate-sealed-secrets.sh -n helicone secret_key "your-s3-secret-key"

# MinIO credentials
./scripts/generate-sealed-secrets.sh -n helicone minio-root-user "admin"
./scripts/generate-sealed-secrets.sh -n helicone minio-root-password "your-minio-password"

# Web application secrets
./scripts/generate-sealed-secrets.sh -n helicone BETTER_AUTH_SECRET "your-auth-secret"
./scripts/generate-sealed-secrets.sh -n helicone STRIPE_SECRET_KEY "sk_test_..."

# AI Gateway API keys
./scripts/generate-sealed-secrets.sh -n helicone openai_api_key "sk-..."
./scripts/generate-sealed-secrets.sh -n helicone anthropic_api_key "sk-ant-..."
```

### Integration with Helm Templates

The encrypted values can be directly used in the `charts/helicone-core/templates/sealed-secrets.yaml` file:

1. Generate the encrypted value:

   ```bash
   ./scripts/generate-sealed-secrets.sh -o postgres-password "my-secret-password"
   ```

2. Replace the placeholder in the template:

   ```yaml
   # Before
   postgres-password: "PLACEHOLDER-ENCRYPT-YOUR-POSTGRES-PASSWORD"

   # After
   postgres-password: "AgBy3i4OJSWK+PiTySYZZA9rO3xvGnVPN..."
   ```

### Troubleshooting

- **"kubeseal CLI is not installed"**: Install kubeseal using the instructions above
- **"kubectl is not configured"**: Ensure kubectl is configured with cluster access
- **"Could not extract encrypted value"**: Check that the key name matches exactly
- **Connection errors**: Verify the sealed-secrets controller is running in your cluster

### Security Notes

- The script creates temporary files in a secure temporary directory
- Temporary files are automatically cleaned up on exit
- The plaintext secret is only stored temporarily during encryption
- Always verify the encrypted output before committing to version control
