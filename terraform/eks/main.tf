# Multi-region EKS deployment
# This file imports the multi-region module configurations

# The multi-region EKS cluster modules are defined in modules.tf
# This approach allows for separate cluster configurations per region

# Default provider (can be used for shared resources if needed)
provider "aws" {
  region = var.region
} 