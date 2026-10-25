mock_provider "aws" {
  mock_resource "aws_sesv2_email_identity" {
    defaults = {
      arn = "arn:aws:ses:eu-west-1:123456789012:identity/example.com"
      dkim_signing_attributes = {
        tokens = ["tok1", "tok2", "tok3"]
      }
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name   = "example"
  domain = "example.com"
}

# SMOKE: the DKIM tokens are computed by SES, so the record map keys are only known after apply; this run applies against the mock provider (whose defaults supply three tokens) to count the emitted records. Real token behaviour is proven in complete.tftest.hcl.
run "test_dns_records_count_six" {
  command = apply

  assert {
    condition     = length(output.dns_records) == 6
    error_message = "Expected 3 DKIM CNAMEs, 1 MX, 1 SPF TXT and 1 DMARC TXT."
  }

  assert {
    condition     = output.dns_records["tok1._domainkey.example.com"].content == "tok1.dkim.amazonses.com" && output.dns_records["tok1._domainkey.example.com"].type == "CNAME"
    error_message = "DKIM CNAME content must be <token>.dkim.amazonses.com."
  }

  assert {
    condition     = output.dns_records["mail.example.com"] != null
    error_message = "MX / SPF records are keyed by the MAIL FROM domain."
  }
}

# SMOKE: runs with apply on the mock provider because record keys depend on computed DKIM tokens.
run "test_dmarc_policy_in_txt" {
  command = apply

  variables {
    dmarc_policy = "reject"
  }

  assert {
    condition     = output.dns_records["_dmarc.example.com"].content == "v=DMARC1; p=reject"
    error_message = "DMARC TXT must carry the configured policy and no rua clause by default."
  }

  assert {
    condition     = output.dns_records["_dmarc.example.com"].type == "TXT"
    error_message = "DMARC record must be TXT."
  }
}

run "test_dmarc_validation" {
  command = plan

  variables {
    dmarc_policy = "strict"
  }

  expect_failures = [var.dmarc_policy]
}

run "test_event_destination_when_sns" {
  command = plan

  variables {
    notifications = {
      sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:ses-events"
      types         = ["Bounce", "RenderingFailure"]
    }
  }

  assert {
    condition     = length(aws_sesv2_configuration_set_event_destination.this) == 1
    error_message = "An event destination must exist when notifications is set."
  }

  assert {
    condition     = aws_sesv2_configuration_set_event_destination.this[0].event_destination[0].matching_event_types == toset(["BOUNCE", "RENDERING_FAILURE"])
    error_message = "Event types must be upper-cased to SES v2 names."
  }
}

run "test_no_event_destination_by_default" {
  command = plan

  assert {
    condition     = length(aws_sesv2_configuration_set_event_destination.this) == 0
    error_message = "No event destination without notifications."
  }
}

run "test_notification_requires_topic" {
  command = plan

  variables {
    notifications = {}
  }

  expect_failures = [output.id]
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null && output.arn == null && output.name == null && output.dns_records == null && output.dkim_tokens == null && output.configuration_set_name == null && output.tags == null
    error_message = "All outputs must be null when create is false."
  }

  assert {
    condition     = length(aws_sesv2_email_identity.this) == 0 && length(aws_sesv2_configuration_set.this) == 0 && length(aws_sesv2_email_identity_mail_from_attributes.this) == 0
    error_message = "No resources may be planned when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    tags = { Owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "z" }
    }
  }

  assert {
    condition     = output.tags.Owner == "x"
    error_message = "var.tags must win over context.extra_tags."
  }

  assert {
    condition     = output.tags.Team == "z"
    error_message = "context.extra_tags must be merged."
  }
}

run "test_tls_required" {
  command = plan

  assert {
    condition     = aws_sesv2_configuration_set.this[0].delivery_options[0].tls_policy == "REQUIRE"
    error_message = "TLS must be required."
  }
}

run "test_domain_validation" {
  command = plan

  variables {
    domain = "Not_A_Host"
  }

  expect_failures = [var.domain]
}

run "test_notification_type_validation" {
  command = plan

  variables {
    notifications = {
      sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:ses-events"
      types         = ["Explode"]
    }
  }

  expect_failures = [var.notifications]
}

run "test_mx_record_priority" {
  command = plan
  assert {
    condition     = output.dns_records["mail.example.com"].priority == 10 && output.dns_records["mail.example.com"].type == "MX"
    error_message = "The MAIL FROM MX record must carry priority 10."
  }
  assert {
    condition     = output.dns_records["_dmarc.example.com"].priority == null
    error_message = "Non-MX records must not carry a priority."
  }
}

run "test_dmarc_rua_when_set" {
  command = plan
  variables { dmarc_report_address = "dmarc-reports@example.com" }
  assert {
    condition     = output.dns_records["_dmarc.example.com"].content == "v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@example.com"
    error_message = "rua must be emitted when dmarc_report_address is set."
  }
}

run "test_dmarc_without_rua" {
  command = plan
  assert {
    condition     = output.dns_records["_dmarc.example.com"].content == "v=DMARC1; p=quarantine"
    error_message = "Without dmarc_report_address the record must end at the policy, with no rua clause."
  }
}

run "test_dmarc_report_address_validation" {
  command = plan
  variables { dmarc_report_address = "not-an-address" }
  expect_failures = [var.dmarc_report_address]
}
