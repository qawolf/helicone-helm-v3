terraform {
    cloud { 
    
    organization = "helicone" 

    workspaces { 
      name = "helicone-s3" 
    } 
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.region
}

resource "aws_s3_bucket" "helm_request_response_storage" {
  bucket = var.bucket_name

  tags = merge({
    Name        = "Helm Request Response Storage"
    Environment = var.environment
    Purpose     = "Request and response storage for Helm"
  }, var.tags)
}

resource "aws_s3_bucket_versioning" "helm_request_response_storage_versioning" {
  bucket = aws_s3_bucket.helm_request_response_storage.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "helm_request_response_storage_encryption" {
  bucket = aws_s3_bucket.helm_request_response_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "helm_request_response_storage_pab" {
  bucket = aws_s3_bucket.helm_request_response_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "helm_request_response_storage_cors" {
  bucket = aws_s3_bucket.helm_request_response_storage.id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
} 

# Data sources for OIDC provider information
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

#################################################################################
# IAM Role for S3 Access via Service Accounts (IRSA)
#################################################################################

# Trust policy for Kubernetes service accounts
data "aws_iam_policy_document" "s3_service_account_trust" {
  count = var.enable_service_account_access ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/${var.eks_oidc_provider}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider}:sub"
      values   = [
        "system:serviceaccount:${var.kubernetes_namespace}:helicone-core-web",
        "system:serviceaccount:${var.kubernetes_namespace}:helicone-core-jawn"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM role for S3 access
resource "aws_iam_role" "s3_service_account" {
  count = var.enable_service_account_access ? 1 : 0

  name               = "${var.bucket_name}-service-account-role"
  assume_role_policy = data.aws_iam_policy_document.s3_service_account_trust[0].json
  description        = "IAM role for Kubernetes service accounts to access S3 bucket ${var.bucket_name}"

  tags = var.tags
}

# IAM policy for S3 bucket access
data "aws_iam_policy_document" "s3_access" {
  count = var.enable_service_account_access ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.helm_request_response_storage.arn,
      "${aws_s3_bucket.helm_request_response_storage.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  count = var.enable_service_account_access ? 1 : 0

  name   = "${var.bucket_name}-service-account-policy"
  policy = data.aws_iam_policy_document.s3_access[0].json

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "s3_service_account" {
  count = var.enable_service_account_access ? 1 : 0

  role       = aws_iam_role.s3_service_account[0].name
  policy_arn = aws_iam_policy.s3_access[0].arn
} 