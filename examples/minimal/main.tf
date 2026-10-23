terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "this" {
  source = "../../"

  name   = "example"
  domain = "example.com"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
}

output "dns_records" {
  description = "DNS records to publish for the domain."
  value       = module.this.dns_records
}
