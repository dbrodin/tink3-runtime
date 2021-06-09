include {
  path = find_in_parent_folders()
}

# Use the official EKS module for now - let's see how it works
# The EKS module could be defined in this source directly.. Up for change that later..
terraform {
  source = get_terragrunt_dir()
}

locals {
  cluster_config = yamldecode(file("${find_in_parent_folders("config.yaml")}"))["eks-cluster"]
  # Get from root. Could be in the config.yaml file
  root_terragrunt_conf = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  region               = local.root_terragrunt_conf.inputs.region
}

dependency "eks-vpc" {
  config_path = "../eks-vpc"

  mock_outputs = {
    vpc_id = "vpc-mocking"
    private_subnets = [
      "subnet-mock1",
      "subnet-mock2",
      "subnet-mock3",
    ]
  }
}

# Generate terraform files to be used
generate "data_sources" {
  path      = "data_sources.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    data "aws_eks_cluster" "cluster" {
      name = module.eks_cluster.cluster_id
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = module.eks_cluster.cluster_id
    }
  EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"
    }
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
  EOF
}

inputs = {
  cluster_config  = local.cluster_config
  vpc_id          = dependency.eks-vpc.outputs.vpc_id
  private_subnets = dependency.eks-vpc.outputs.private_subnets
}
