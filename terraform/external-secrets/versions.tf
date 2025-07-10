# TODO Ensure that the other terraform modules are also using a versions.tf file
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  cloud { 
    organization = "helicone" 

    workspaces {
      name = "helicone-external-secrets"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
} 