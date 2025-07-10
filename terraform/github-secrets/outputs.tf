#################################################################################
# GitHub Repository Secrets Outputs
#################################################################################

output "github_repository_secrets" {
  description = "List of GitHub repository secrets created"
  value = [
    "AWS_SECRETS_SYNC_ROLE_ARN",
    "AWS_REGION", 
    "EKS_CLUSTER_NAME",
    "SECRET_PREFIX",
    "NAMESPACE"
  ]
}

#################################################################################
# IAM Resources Outputs
#################################################################################

output "github_actions_secrets_sync_role_arn" {
  description = "ARN of the IAM role for GitHub Actions secrets sync"
  value       = aws_iam_role.github_actions_secrets_sync.arn
}

output "github_actions_secrets_sync_role_name" {
  description = "Name of the IAM role for GitHub Actions secrets sync"
  value       = aws_iam_role.github_actions_secrets_sync.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
}

#################################################################################
# Helper Information
#################################################################################

output "repository_full_name" {
  description = "Full GitHub repository name (org/repo)"
  value       = "${var.github_org}/${var.github_repository}"
}

output "workflow_permissions_summary" {
  description = "Summary of permissions granted to GitHub Actions workflow"
  value = {
    secrets_manager = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue", 
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    eks = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    kubeseal_cluster_access = var.enable_kubeseal_cluster_access ? ["eks:AccessKubernetesApi"] : []
  }
}

#################################################################################
# Next Steps Information
#################################################################################

output "next_steps" {
  description = "Next steps to complete the setup"
  value = {
    workflow_file = "Ensure .github/workflows/sync-secrets.yml exists in your repository"
    test_workflow = "Run the workflow manually to test: gh workflow run sync-secrets.yml"
    verify_secrets = "Check that secrets are created in your GitHub repository settings"
    monitor_runs = "Monitor workflow runs in GitHub Actions tab"
  }
} 