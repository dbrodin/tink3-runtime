output "vpc_endpoint_service_id" {
  value = try(aws_vpc_endpoint_service.vpc_endpoint_service[*].id, "")
}

output "vpc_endpoint_service_base_endpoint_dns_names" {
  value = try(aws_vpc_endpoint_service.vpc_endpoint_service[*].base_endpoint_dns_names, "")
}

output "vpc_endpoint_service_private_dns_name" {
  value = try(aws_vpc_endpoint_service.vpc_endpoint_service[*].private_dns_name, "")
}
