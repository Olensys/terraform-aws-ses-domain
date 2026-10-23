variable "name" {
  description = "Name of the SES configuration set, also used for tags. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,64}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,64}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Domain to verify as an SES identity, for example example.com."
  type        = string
  validation {
    condition     = can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}$", var.domain))
    error_message = "domain must be a lowercase hostname matching ^([a-z0-9-]+\\.)+[a-z]{2,}$."
  }
}

variable "mail_from_subdomain" {
  description = "Subdomain of domain used as the custom MAIL FROM domain."
  type        = string
  default     = "mail"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.mail_from_subdomain))
    error_message = "mail_from_subdomain must be a single lowercase DNS label."
  }
}

variable "notifications" {
  description = "SNS event notifications. null disables the event destination. types uses TitleCase names: Bounce, Complaint, Delivery, Send, Reject, Open, Click, RenderingFailure, DeliveryDelay, Subscription."
  type = object({
    sns_topic_arn = optional(string)
    types         = optional(list(string), ["Bounce", "Complaint"])
  })
  default = null
  validation {
    condition = var.notifications == null || (
      length(var.notifications.types) > 0 &&
      alltrue([for t in var.notifications.types : contains(["Bounce", "Complaint", "Delivery", "Send", "Reject", "Open", "Click", "RenderingFailure", "DeliveryDelay", "Subscription"], t)])
    )
    error_message = "notifications.types must be a non-empty list of: Bounce, Complaint, Delivery, Send, Reject, Open, Click, RenderingFailure, DeliveryDelay, Subscription."
  }
}

variable "dmarc_policy" {
  description = "DMARC policy emitted in the _dmarc TXT record."
  type        = string
  default     = "quarantine"
  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be one of none, quarantine, reject."
  }
}

variable "tags" {
  description = "Tags merged onto every taggable resource, applied last."
  type        = map(string)
  default     = {}
}
