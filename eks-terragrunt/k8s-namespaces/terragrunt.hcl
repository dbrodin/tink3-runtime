include {
  path = find_in_parent_folders()
}

terraform {
  source = get_terragrunt_dir()
}

locals {
  namespace_config     = yamldecode(file("${find_in_parent_folders("config.yaml")}"))["k8s-namespaces"]
  root_terragrunt_conf = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  region               = local.root_terragrunt_conf.inputs.region
}

dependency "eks-cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_id = "cluster_id"
  }
}

generate "data_sources" {
  path      = "data_sources.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    data "aws_eks_cluster" "cluster" {
      name = var.cluster_id
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = var.cluster_id
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
  namespace_config = local.namespace_config
  cluster_id       = dependency.eks-cluster.outputs.cluster_id
}
