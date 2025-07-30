terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# Cloudflare Provider Configuration
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Locals for processing DNS records and zones
locals {
  # Process DNS records with zone IDs (zone_id is now required)
  processed_dns_records = {
    for idx, record in var.dns_records : "${record.zone_name}-${record.subdomain}" => merge(record, {
      zone_id = record.zone_id != null ? record.zone_id : var.cloudflare_zones[record.zone_name].zone_id
      record_name = record.subdomain == "@" ? record.zone_name : "${record.subdomain}.${record.zone_name}"
    }) if record.enabled && var.cloudflare_zones[record.zone_name].enabled
  }
}

# Create DNS records for all configured DNS records
resource "cloudflare_dns_record" "dns_records" {
  for_each = local.processed_dns_records

  zone_id = each.value.zone_id
  name    = each.value.subdomain
  content = each.value.target
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = each.value.proxied

  comment = coalesce(
    each.value.comment,
    "Managed by Terraform - ${each.value.subdomain}.${each.value.zone_name} -> ${each.value.target}"
  )
}

# Certificate validation records for ACM certificates
resource "cloudflare_dns_record" "certificate_validation" {
  for_each = {
    for dvo in var.certificate_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      # Find the appropriate zone for this domain
      zone_id = try([
        for zone_name, config in var.cloudflare_zones : config.zone_id
        if endswith(dvo.domain_name, zone_name) && config.enabled
      ][0], null)
    }
    if length(var.certificate_validation_options) > 0
  }

  zone_id = each.value.zone_id
  name    = each.value.name
  content = each.value.record
  type    = each.value.type
  ttl     = 60

  comment = "Managed by Terraform - ACM certificate validation for ${each.key}"
  
  lifecycle {
    ignore_changes = [content, name, type] 
  }
}
