output "accelerator_arn" {
  description = "ARN of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.id
}

output "accelerator_dns_name" {
  description = "DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.dns_name
}

output "accelerator_dual_stack_dns_name" {
  description = "Dual-stack DNS name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.dual_stack_dns_name
}

output "accelerator_hosted_zone_id" {
  description = "Hosted zone ID of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.hosted_zone_id
}

output "accelerator_ip_sets" {
  description = "IP address sets associated with the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.ip_sets
}

output "tcp_listener_arn" {
  description = "ARN of the TCP listener (HTTPS)"
  value       = aws_globalaccelerator_listener.tcp_listener.id
}

output "tcp_listener_arn_http" {
  description = "ARN of the TCP listener (HTTP)"
  value       = aws_globalaccelerator_listener.tcp_listener_http.id
}

output "endpoint_group_arns" {
  description = "Map of region to endpoint group ARN (HTTPS)"
  value       = { for region, group in aws_globalaccelerator_endpoint_group.endpoint_groups : region => group.id }
}

output "endpoint_group_arns_http" {
  description = "Map of region to endpoint group ARN (HTTP)"
  value       = { for region, group in aws_globalaccelerator_endpoint_group.endpoint_groups_http : region => group.id }
}

output "accelerator_name" {
  description = "Name of the Global Accelerator"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.name
}

output "accelerator_enabled" {
  description = "Whether the Global Accelerator is enabled"
  value       = aws_globalaccelerator_accelerator.helicone_global_accelerator.enabled
} 