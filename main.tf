data "aws_region" "current" {}

locals {
  tags = merge(var.context.extra_tags, var.tags)

  mail_from_domain = "${var.mail_from_subdomain}.${var.domain}"
  region           = data.aws_region.current.region

  # SES v2 event type names are upper snake case; the input uses TitleCase.
  event_type_map = {
    Bounce           = "BOUNCE"
    Complaint        = "COMPLAINT"
    Delivery         = "DELIVERY"
    Send             = "SEND"
    Reject           = "REJECT"
    Open             = "OPEN"
    Click            = "CLICK"
    RenderingFailure = "RENDERING_FAILURE"
    DeliveryDelay    = "DELIVERY_DELAY"
    Subscription     = "SUBSCRIPTION"
  }

  notifications_enabled = var.create && var.notifications != null

  dkim_tokens = var.create ? aws_sesv2_email_identity.this[0].dkim_signing_attributes[0].tokens : []

  dns_records = var.create ? merge(
    {
      for token in local.dkim_tokens : "${token}._domainkey.${var.domain}" => {
        name    = "${token}._domainkey.${var.domain}"
        type    = "CNAME"
        content = "${token}.dkim.amazonses.com"
        ttl     = 300
        proxied = false
        comment = "SES Easy DKIM for ${var.domain}"
      }
    },
    {
      (local.mail_from_domain) = {
        name    = local.mail_from_domain
        type    = "MX"
        content = "feedback-smtp.${local.region}.amazonses.com"
        ttl     = 300
        proxied = false
        comment = "MX priority 10"
      }
      "spf.${local.mail_from_domain}" = {
        name    = local.mail_from_domain
        type    = "TXT"
        content = "v=spf1 include:amazonses.com -all"
        ttl     = 300
        proxied = false
        comment = "SPF for the SES MAIL FROM domain"
      }
      "_dmarc.${var.domain}" = {
        name    = "_dmarc.${var.domain}"
        type    = "TXT"
        content = "v=DMARC1; p=${var.dmarc_policy}; rua=mailto:dmarc@${var.domain}"
        ttl     = 300
        proxied = false
        comment = "DMARC policy for ${var.domain}"
      }
    }
  ) : null
}

resource "aws_sesv2_configuration_set" "this" {
  count = var.create ? 1 : 0

  configuration_set_name = var.name

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }

  tags = local.tags
}

resource "aws_sesv2_email_identity" "this" {
  count = var.create ? 1 : 0

  email_identity         = var.domain
  configuration_set_name = aws_sesv2_configuration_set.this[0].configuration_set_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }

  tags = local.tags
}

resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  count = var.create ? 1 : 0

  email_identity         = aws_sesv2_email_identity.this[0].email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = "REJECT_MESSAGE"
}

resource "aws_sesv2_configuration_set_event_destination" "this" {
  # A missing sns_topic_arn is rejected by the precondition on output "id".
  count = local.notifications_enabled && try(var.notifications.sns_topic_arn, null) != null ? 1 : 0

  configuration_set_name = aws_sesv2_configuration_set.this[0].configuration_set_name
  event_destination_name = "${var.name}-sns"

  event_destination {
    enabled              = true
    matching_event_types = [for t in var.notifications.types : local.event_type_map[t]]

    sns_destination {
      topic_arn = var.notifications.sns_topic_arn
    }
  }
}
