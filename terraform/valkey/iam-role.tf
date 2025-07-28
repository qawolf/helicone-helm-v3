# IAM role for EKS Pod Identity to access ElastiCache
resource "aws_iam_role" "valkey_pod_identity_role" {
  name = "${var.valkey_cache_name}-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.valkey_cache_name}-pod-identity-role"
  })
}

# IAM policy for ElastiCache access
resource "aws_iam_policy" "valkey_access_policy" {
  name        = "${var.valkey_cache_name}-access-policy"
  description = "Policy for accessing Valkey ElastiCache cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups", 
          "elasticache:DescribeServerlessCaches",
          "elasticache:Connect"
        ]
        Resource = [
          aws_elasticache_serverless_cache.valkey.arn
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.valkey_cache_name}-access-policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "valkey_policy_attachment" {
  role       = aws_iam_role.valkey_pod_identity_role.name
  policy_arn = aws_iam_policy.valkey_access_policy.arn
} 