# terraform-aws-ses-domain

SES domain identity with Easy DKIM, custom MAIL FROM, DMARC guidance, configuration set and event notifications

## Opinions

- TLS is required for delivery (`tls_policy = "REQUIRE"`); reputation metrics and sending are enabled.
- Easy DKIM with RSA-2048 signing keys.
- Custom MAIL FROM domain (`mail.<domain>` by default) with `REJECT_MESSAGE` on MX failure.
- DMARC policy defaults to `quarantine`; DMARC reports are off unless `dmarc_report_address` is set.
- The MX record carries priority 10.
- DNS records are emitted, not created, in the record shape consumed by [terraform-cloudflare-dns](https://github.com/Olensys/terraform-cloudflare-dns) (`name`, `type`, `content`, `ttl`, `priority`, `proxied`, `comment`). Map keys are unique per record; the `name` field is the DNS name. `priority` is 10 on the MX record and null elsewhere; consumers need terraform-cloudflare-dns 1.1.0 or later.
- SNS event destination is created only when `notifications` is set; types are given in TitleCase (for example `Bounce`) and upper-cased to the SES v2 names.

## Usage

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"
  context = var.context
}

module "ses_domain" {
  source  = "git::https://github.com/Olensys/terraform-aws-ses-domain.git?ref=v1.1.0"
  name    = module.naming.name
  context = var.context

  domain = "example.com"

  tags = module.naming.tags
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_sesv2_configuration_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set) | resource |
| [aws_sesv2_configuration_set_event_destination.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set_event_destination) | resource |
| [aws_sesv2_email_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity) | resource |
| [aws_sesv2_email_identity_mail_from_attributes.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity_mail_from_attributes) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to verify as an SES identity, for example example.com. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the SES configuration set, also used for tags. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_dmarc_policy"></a> [dmarc\_policy](#input\_dmarc\_policy) | DMARC policy emitted in the \_dmarc TXT record. | `string` | `"quarantine"` | no |
| <a name="input_dmarc_report_address"></a> [dmarc\_report\_address](#input\_dmarc\_report\_address) | Mailbox that receives DMARC aggregate reports (emitted as rua=mailto:...). Null emits no rua clause, which disables reporting. | `string` | `null` | no |
| <a name="input_mail_from_subdomain"></a> [mail\_from\_subdomain](#input\_mail\_from\_subdomain) | Subdomain of domain used as the custom MAIL FROM domain. | `string` | `"mail"` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | SNS event notifications. null disables the event destination. types uses TitleCase names: Bounce, Complaint, Delivery, Send, Reject, Open, Click, RenderingFailure, DeliveryDelay, Subscription. | <pre>object({<br/>    sns_topic_arn = optional(string)<br/>    types         = optional(list(string), ["Bounce", "Complaint"])<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every taggable resource, applied last. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the SES domain identity. Null when create is false. |
| <a name="output_configuration_set_name"></a> [configuration\_set\_name](#output\_configuration\_set\_name) | Name of the SES configuration set. Null when create is false. |
| <a name="output_dkim_tokens"></a> [dkim\_tokens](#output\_dkim\_tokens) | Easy DKIM tokens issued by SES. Null when create is false. |
| <a name="output_dns_records"></a> [dns\_records](#output\_dns\_records) | DNS records to publish, keyed by record name, in the record shape consumed by terraform-cloudflare-dns (name, type, content, ttl, priority, proxied, comment): three DKIM CNAMEs, the MAIL FROM MX (priority 10; priority is null on every other record) and SPF TXT, and the DMARC TXT. The SPF entry key is prefixed spf. so it does not collide with the MX key; its name field is the MAIL FROM domain. Known only after apply. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | Identifier of the SES domain identity (its ARN). Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Verified domain name. Null when create is false. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to every taggable resource, with context.extra\_tags merged in. Null when create is false. |
<!-- END_TF_DOCS -->
