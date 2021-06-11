variable "acceptance_required" {
  default = true
}

variable "vpc_endpoint_service_config" {
  type = map(object({
    allowed_aws_accounts_principals = list(string)
    nlb_arns_to_expose              = list(string)
    tags                            = map(string)
  }))
}
