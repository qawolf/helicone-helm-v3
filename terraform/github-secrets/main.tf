# Data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

#################################################################################
# GitHub Repository Secrets
#################################################################################

# AWS Secrets Sync Role ARN for GitHub Actions
resource "github_actions_secret" "aws_secrets_sync_role_arn" {
  repository      = var.github_repository
  secret_name     = "AWS_SECRETS_SYNC_ROLE_ARN"
  plaintext_value = aws_iam_role.github_actions_secrets_sync.arn
}

# AWS Region
resource "github_actions_secret" "aws_region" {
  repository      = var.github_repository
  secret_name     = "AWS_REGION"
  plaintext_value = var.aws_region
}

# EKS Cluster Name
resource "github_actions_secret" "eks_cluster_name" {
  repository      = var.github_repository
  secret_name     = "EKS_CLUSTER_NAME"
  plaintext_value = var.eks_cluster_name
}

# Secret Prefix (matches External Secrets configuration)
resource "github_actions_secret" "secret_prefix" {
  repository      = var.github_repository
  secret_name     = "SECRET_PREFIX"
  plaintext_value = var.secret_prefix
}

# Kubernetes Namespace
resource "github_actions_secret" "namespace" {
  repository      = var.github_repository
  secret_name     = "NAMESPACE"
  plaintext_value = var.kubernetes_namespace
}

#################################################################################
# IAM Role for GitHub Actions (OIDC)
#################################################################################

# GitHub OIDC Provider (if not already exists)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",  # GitHub Actions OIDC thumbprint
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"   # Backup thumbprint
  ]

  tags = var.tags
}

# Trust policy for GitHub Actions
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repository}:*"]
    }
  }
}

# IAM role for GitHub Actions secrets sync
resource "aws_iam_role" "github_actions_secrets_sync" {
  name               = "${var.resource_prefix}-github-actions-secrets-sync"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  description        = "IAM role for GitHub Actions to sync secrets from AWS Secrets Manager"

  tags = var.tags
}

# IAM policy for GitHub Actions secrets sync
data "aws_iam_policy_document" "github_actions_secrets_sync_policy" {
  # Secrets Manager permissions
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:${local.partition}:secretsmanager:${var.aws_region}:${local.account_id}:secret:${var.secret_prefix}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }

  # EKS permissions for kubeseal and cluster access
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi"
    ]
    resources = [
      "arn:${local.partition}:eks:${var.aws_region}:${local.account_id}:cluster/${var.eks_cluster_name}"
    ]
  }

  # Additional IAM permissions for role assumption debugging
  statement {
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_secrets_sync" {
  name   = "${var.resource_prefix}-github-actions-secrets-sync-policy"
  role   = aws_iam_role.github_actions_secrets_sync.id
  policy = data.aws_iam_policy_document.github_actions_secrets_sync_policy.json
}

#################################################################################
# Optional: GitHub Repository Settings
#################################################################################

# Configure repository settings if enabled
resource "github_repository" "main" {
  count = var.manage_repository_settings ? 1 : 0

  name        = var.github_repository
  description = "Helicone Helm Charts v3 - GitOps deployment with External Secrets"
  
  visibility = var.repository_visibility
  
  # Security settings
  vulnerability_alerts                    = true
  delete_branch_on_merge                 = true
  allow_merge_commit                     = true
  allow_squash_merge                     = true
  allow_rebase_merge                     = false
  allow_auto_merge                       = true
  squash_merge_commit_title              = "PR_TITLE"
  squash_merge_commit_message            = "PR_BODY"
  
  # Branch protection will be handled separately
  has_issues      = true
  has_projects    = true
  has_wiki        = false
  has_downloads   = false
  
  topics = [
    "helm",
    "kubernetes",
    "gitops",
    "argocd",
    "external-secrets",
    "sealed-secrets",
    "helicone"
  ]
}

# Branch protection for main branch
resource "github_branch_protection" "main" {
  count = var.manage_repository_settings ? 1 : 0

  repository_id = github_repository.main[0].node_id
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = [
      "sync-secrets"  # GitHub Actions workflow
    ]
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
    require_code_owner_reviews      = true
    dismiss_stale_reviews          = true
    restrict_dismissals            = false
  }

  enforce_admins         = false
  allows_deletions       = false
  allows_force_pushes    = false
  require_signed_commits = false
} 