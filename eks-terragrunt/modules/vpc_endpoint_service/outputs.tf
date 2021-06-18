output "vpc_endpoint_service" {
  value = {
    for endpoint, values in aws_vpc_endpoint_service.vpc_endpoint_service :
    endpoint => {
      id               = values.id
      base_dns_names   = values.base_endpoint_dns_names
      private_dns_name = values.private_dns_name
      service_name     = values.service_name
    }
  }
}
