output "id" {
  description = "Identifier of the SES domain identity (its ARN). Null when create is false."
  value       = var.create ? aws_sesv2_email_identity.this[0].arn : null

  precondition {
    condition     = !local.notifications_enabled || try(var.notifications.sns_topic_arn, null) != null
    error_message = "notifications.sns_topic_arn is required when notifications is set."
  }
}

output "name" {
  description = "Verified domain name. Null when create is false."
  value       = var.create ? var.domain : null
}

output "arn" {
  description = "ARN of the SES domain identity. Null when create is false."
  value       = var.create ? aws_sesv2_email_identity.this[0].arn : null
}

output "dns_records" {
  description = "DNS records to publish, keyed by record name, in the record shape consumed by terraform-cloudflare-dns (name, type, content, ttl, priority, proxied, comment): three DKIM CNAMEs, the MAIL FROM MX (priority 10; priority is null on every other record) and SPF TXT, and the DMARC TXT. The SPF entry key is prefixed spf. so it does not collide with the MX key; its name field is the MAIL FROM domain. Known only after apply. Null when create is false."
  value       = local.dns_records
}

output "configuration_set_name" {
  description = "Name of the SES configuration set. Null when create is false."
  value       = var.create ? aws_sesv2_configuration_set.this[0].configuration_set_name : null
}

output "dkim_tokens" {
  description = "Easy DKIM tokens issued by SES. Null when create is false."
  value       = var.create ? local.dkim_tokens : null
}

output "tags" {
  description = "Tags applied to every taggable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.tags : null
}
