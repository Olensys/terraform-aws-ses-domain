# Run only by the nightly integration workflow, against real cloud credentials.
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = length(output.dns_records) == 6
    error_message = "Expected six DNS records."
  }
}
