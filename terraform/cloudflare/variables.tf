variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

# ACM certificate validation options
variable "certificate_validation_options" {
  description = "List of certificate validation options from ACM certificate"
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
  default = []
}

# Flexible DNS records configuration
variable "dns_records" {
  description = "List of DNS records to create in Cloudflare zones"
  type = list(object({
    zone_name             = string              # e.g., "helicone.ai"
    zone_id               = optional(string)    # Optional: provide zone_id directly, otherwise will be looked up
    subdomain             = string              # e.g., "api", "app", "filevine"
    target                = string              # Load balancer hostname or target
    type                  = optional(string, "CNAME")  # Record type, defaults to CNAME
    ttl                   = optional(number, 1)        # TTL, defaults to 1 (auto when proxied)
    proxied               = optional(bool, true)       # Whether to proxy through Cloudflare
    comment               = optional(string)           # Optional comment for the record
    enabled               = optional(bool, true)       # Whether to create this record
  }))
  default = []
  
  validation {
    condition = alltrue([
      for record in var.dns_records : record.zone_name != "" && record.subdomain != "" && record.target != ""
    ])
    error_message = "Each DNS record must have non-empty zone_name, subdomain, and target."
  }
}

# Zone configurations
variable "cloudflare_zones" {
  description = "Map of zone names to their configuration (zone_id is required)"
  type = map(object({
    zone_id = string  # Zone ID is required
    enabled = optional(bool, true)
  }))
  default = {
    "helicone.ai" = {
      zone_id = "391fdcbd3e8173410d3353d4e78f82a4"
      enabled = true
    }
  }
} 