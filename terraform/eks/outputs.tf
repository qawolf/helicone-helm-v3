output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_version" {
  description = "Version of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.platform_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.eks_nodes.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.status
}

output "node_group_role_arn" {
  description = "ARN of the IAM role for the node group"
  value       = aws_iam_role.eks_node_role.arn
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for the EBS CSI driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_driver[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for the cluster autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "cluster_autoscaler_pod_identity_association_arn" {
  description = "ARN of the EKS Pod Identity Association for cluster autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_eks_pod_identity_association.cluster_autoscaler[0].association_arn : null
}

output "kubectl_config" {
  description = "kubectl config command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}"
}

# Load balancer hostname for other modules (Route53/ACM and Cloudflare)
output "load_balancer_hostname" {
  description = "Load balancer hostname from the ingress controller"
  value       = try(data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname, null)
}

# Load balancer zone ID for Route53 configuration
output "load_balancer_zone_id" {
  description = "Load balancer zone ID from the ingress controller"
  value       = var.enable_ingress_nginx_lb_lookup ? try(data.aws_lb.ingress_nginx[0].zone_id, null) : null
}

output "ingress_nginx_load_balancer_zone_id" {
  description = "The Route53 zone ID of the ingress-nginx load balancer"
  value       = var.enable_ingress_nginx_lb_lookup ? data.aws_lb.ingress_nginx[0].zone_id : null
}

# Pod Identity Agent addon outputs
output "pod_identity_agent_addon_arn" {
  description = "ARN of the EKS Pod Identity Agent addon"
  value       = var.enable_pod_identity_agent ? aws_eks_addon.pod_identity_agent[0].arn : null
}

output "pod_identity_agent_addon_version" {
  description = "Version of the EKS Pod Identity Agent addon"
  value       = var.enable_pod_identity_agent ? aws_eks_addon.pod_identity_agent[0].addon_version : null
}

output "pod_identity_agent_addon_name" {
  description = "Name of the EKS Pod Identity Agent addon"
  value       = var.enable_pod_identity_agent ? aws_eks_addon.pod_identity_agent[0].addon_name : null
}

#################################################################################
# AWS Load Balancer Controller Outputs
#################################################################################

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller_role[0].arn : null
}

output "alb_controller_role_name" {
  description = "Name of the AWS Load Balancer Controller IAM role"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller_role[0].name : null
}

output "alb_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM policy"
  value       = var.enable_alb_controller && var.alb_controller_policy_arn == "" ? aws_iam_policy.alb_controller_policy[0].arn : var.alb_controller_policy_arn
}

output "alb_controller_pod_identity_association_arn" {
  description = "ARN of the AWS Load Balancer Controller Pod Identity Association"
  value       = var.enable_alb_controller ? aws_eks_pod_identity_association.alb_controller[0].association_arn : null
}

output "alb_controller_namespace" {
  description = "Namespace for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? var.alb_controller_namespace : null
}

# AI Gateway ALB Outputs
output "ai_gateway_alb_arn" {
  description = "ARN of the AI Gateway ALB (created by AWS Load Balancer Controller)"
  value       = try(data.aws_lb.ai_gateway_alb[0].arn, null)
}

output "ai_gateway_alb_dns_name" {
  description = "DNS name of the AI Gateway ALB"
  value       = try(data.aws_lb.ai_gateway_alb[0].dns_name, null)
}

output "ai_gateway_alb_zone_id" {
  description = "Zone ID of the AI Gateway ALB"
  value       = try(data.aws_lb.ai_gateway_alb[0].zone_id, null)
} 