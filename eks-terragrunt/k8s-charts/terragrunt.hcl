include {
  path = find_in_parent_folders()
}

# Deploy charts defined in inputs = {}
terraform {
  source = "../modules/supporting_helm_charts"
}

locals {
  root_terragrunt_conf = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  region               = local.root_terragrunt_conf.inputs.region
}

# Declare dependencies for the k8s-charts
dependency "eks-cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_id = "cluster_id"
  }
}

dependency "k8s-namespaces" {
  config_path = "../k8s-namespaces"
}

# Generate terraform files to be used
generate "data_sources" {
  path      = "data_sources.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "cluster_id" {
      type = string
    }
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
    provider "kubectl" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
      load_config_file       = false
    }
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }
  EOF
}

generate "versions" {
  path      = "provider_versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        kubectl = {
          source  = "gavinbunney/kubectl"
          version = ">= 1.7.0"
        }
      }
    }
  EOF
}

inputs = {
  cluster_id = dependency.eks-cluster.outputs.cluster_id

  helm_release = {
    ingress-nginx = {
      chart_name    = "ingress-nginx"
      chart_repo    = "https://kubernetes.github.io/ingress-nginx"
      chart_version = "3.33.0"
      namespace     = "ingress-nginx"
    }
  }
}
