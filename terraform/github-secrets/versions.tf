terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "helicone"
    workspaces {
      name = "helicone-github-secrets"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.0"
    }
  }

  # Optional: Configure Terraform Cloud/Enterprise
  # Uncomment and customize for your organization
  # cloud {
  #   organization = "helicone"
  #   workspaces {
  #     name = "helicone-github-secrets"
  #   }
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "github" {
  # Configure via environment variables:
  # GITHUB_TOKEN - Personal access token or GitHub App token
  # GITHUB_OWNER - Organization or user name (optional, can be set via variables)
  
  owner = var.github_org
} 