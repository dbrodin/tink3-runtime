resource "aws_vpc_endpoint_service" "vpc_endpoint_service" {
  for_each = {
    for endpoint, config in var.vpc_endpoint_service_config :
    endpoint => config
    if try(length(config["nlb_arns_to_expose"]) > 0, false)
  }

  allowed_principals         = lookup(each.value, "allowed_aws_accounts_principals", [])
  acceptance_required        = var.acceptance_required
  network_load_balancer_arns = lookup(each.value, "nlb_arns_to_expose", [])
  tags                       = lookup(each.value, "tags", {})
}
