# Changelog

## 1.0.0

- SES v2 domain identity with Easy DKIM (RSA-2048), custom MAIL FROM with reject on MX failure, TLS-required configuration set and optional SNS event destination.
- `dns_records` output emitting DKIM CNAMEs, MAIL FROM MX and SPF, and DMARC TXT in the terraform-cloudflare-dns record shape.
