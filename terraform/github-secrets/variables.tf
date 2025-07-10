#################################################################################
# General Configuration
#################################################################################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "resource_prefix" {
  description = "Prefix for AWS resource names"
  type        = string
  default     = "helicone"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.resource_prefix))
    error_message = "Resource prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "secret_prefix" {
  description = "Prefix for secret names in AWS Secrets Manager (must match external-secrets module)"
  type        = string
  default     = "helicone"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]+$", var.secret_prefix))
    error_message = "Secret prefix must contain only valid AWS Secrets Manager characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Helicone"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

#################################################################################
# GitHub Configuration
#################################################################################

variable "github_org" {
  description = "GitHub organization name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.github_org))
    error_message = "GitHub organization must contain only alphanumeric characters and hyphens."
  }
}

variable "github_repository" {
  description = "GitHub repository name (without org prefix)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.github_repository))
    error_message = "GitHub repository name must contain only alphanumeric characters, dots, underscores, and hyphens."
  }
}

variable "manage_repository_settings" {
  description = "Whether to manage GitHub repository settings via Terraform"
  type        = bool
  default     = false
}

variable "repository_visibility" {
  description = "GitHub repository visibility (public, private, internal)"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be 'public', 'private', or 'internal'."
  }
}

#################################################################################
# EKS Configuration
#################################################################################

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.eks_cluster_name))
    error_message = "EKS cluster name must contain only alphanumeric characters and hyphens."
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace where Helicone will be deployed"
  type        = string
  default     = "helicone"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.kubernetes_namespace))
    error_message = "Kubernetes namespace must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "enable_kubeseal_cluster_access" {
  description = "Enable cluster access for kubeseal operations (requires additional EKS permissions)"
  type        = bool
  default     = true
}

#################################################################################
# GitHub OIDC Provider Configuration
#################################################################################

variable "create_github_oidc_provider" {
  description = "Whether to create a GitHub OIDC provider (set to false if one already exists)"
  type        = bool
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  description = "ARN of existing GitHub OIDC provider (required if create_github_oidc_provider is false)"
  type        = string
  default     = ""

  validation {
    condition = var.create_github_oidc_provider == true || (
      var.create_github_oidc_provider == false && 
      can(regex("^arn:aws:iam::[0-9]+:oidc-provider/token.actions.githubusercontent.com$", var.existing_github_oidc_provider_arn))
    )
    error_message = "If create_github_oidc_provider is false, existing_github_oidc_provider_arn must be a valid GitHub OIDC provider ARN."
  }
} 