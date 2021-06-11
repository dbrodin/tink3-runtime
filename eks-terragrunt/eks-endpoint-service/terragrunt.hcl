include {
  path = find_in_parent_folders()
}

terraform {
  source = "../modules/vpc_endpoint_service"
}

locals {
  vpc_endpoint_service_config = yamldecode(file("${find_in_parent_folders("config.yaml")}"))["eks-vpc-endpoint-service"]
}

dependencies {
  paths = ["../eks-vpc", "../eks-cluster", "../k8s-namespaces", "../k8s-charts"]
}

inputs = {
  vpc_endpoint_service_config = local.vpc_endpoint_service_config
}
