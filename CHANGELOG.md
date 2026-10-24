# Changelog

## [1.0.2](https://github.com/Olensys/terraform-aws-ses-domain/compare/v1.0.1...v1.0.2) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([c4406cc](https://github.com/Olensys/terraform-aws-ses-domain/commit/c4406cc3d4392c5e9f3fe2f050f31667eba12bb9))

## 1.0.1

### Fixes

- render declared provider constraints in docs and skip .terraform in trivy hook

## 1.0.0

- SES v2 domain identity with Easy DKIM (RSA-2048), custom MAIL FROM with reject on MX failure, TLS-required configuration set and optional SNS event destination.
- `dns_records` output emitting DKIM CNAMEs, MAIL FROM MX and SPF, and DMARC TXT in the terraform-cloudflare-dns record shape.
