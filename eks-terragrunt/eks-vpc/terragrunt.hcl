include {
  path = find_in_parent_folders()
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.1.0"
}

locals {
  vpc_config           = yamldecode(file("${find_in_parent_folders("config.yaml")}"))["vpc-config"]
  cluster_config       = yamldecode(file("${find_in_parent_folders("config.yaml")}"))["eks-cluster"]
  cluster_name         = local.cluster_config["cluster_name"]
  root_terragrunt_conf = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  region               = local.root_terragrunt_conf.inputs.region
  availability_zones   = formatlist("${local.region}%s", ["a", "b", "c"])
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"
    }
  EOF
}

# Using config.yaml for inputs
# reference for tagging subnets:
# https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
inputs = {
  name                 = local.vpc_config["name"]
  cidr                 = local.vpc_config["cidr"]
  azs                  = local.availability_zones
  private_subnets      = local.vpc_config["private_subnets"]
  public_subnets       = local.vpc_config["public_subnets"]
  tags                 = local.vpc_config["tags"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "Maintainer"                                  = local.vpc_config["tags"]["Maintainer"]
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "Maintainer"                                  = local.vpc_config["tags"]["Maintainer"]
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
