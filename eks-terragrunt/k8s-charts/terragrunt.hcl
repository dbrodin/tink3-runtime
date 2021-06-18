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
dependency "eks-vpc" {
  config_path = "../eks-vpc"

  mock_outputs = {
    vpc_id = "vpc-mocking"
  }
}

dependency "eks-cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_id                           = "cluster_id"
    cluster_oidc_issuer_url              = "oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE0123"
    aws_loadbalancer_controller_role_arn = "arn:aws:iam::111122223333:role/AmazonEKSLoadBalancerControllerRole"
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
  cluster_id                           = dependency.eks-cluster.outputs.cluster_id
  cluster_oidc_issuer_url              = dependency.eks-cluster.outputs.cluster_oidc_issuer_url
  aws_loadbalancer_controller_role_arn = dependency.eks-cluster.outputs.aws_loadbalancer_controller_role_arn

  helm_release = {
    ingress-nginx = {
      chart_name    = "ingress-nginx"
      chart         = "ingress-nginx"
      chart_repo    = "https://kubernetes.github.io/ingress-nginx"
      chart_version = "3.33.0"
      namespace     = "ingress-nginx"
      deploy_config = []
    },
    aws-load-balancer-controller = {
      chart_name    = "aws-load-balancer-controller"
      chart         = "aws-load-balancer-controller"
      chart_repo    = "https://aws.github.io/eks-charts"
      chart_version = "1.2.1"
      namespace     = "kube-system"
      deploy_config = [{
        force_helm_update           = false
        recreate_pods_during_update = false
        wait_for_rollout            = true
        cleanup_on_fail             = false
        skip_crds                   = false
        verify                      = false
        values = [
          yamlencode({
            clusterName = dependency.eks-cluster.outputs.cluster_id
            serviceAccount = {
              create = false
              name   = "aws-load-balancer-controller"
            }
            vpcId  = dependency.eks-vpc.outputs.vpc_id
            region = local.region
          })
        ]
      }]
    },
    kubernetes-external-secrets = {
      chart_name    = "kubernetes-external-secrets"
      chart         = "kubernetes-external-secrets"
      chart_repo    = "https://external-secrets.github.io/kubernetes-external-secrets/"
      chart_version = "8.1.2"
      namespace     = "external-secrets"
      deploy_config = [{
        force_helm_update           = false
        recreate_pods_during_update = true
        wait_for_rollout            = true
        cleanup_on_fail             = false
        skip_crds                   = false
        verify                      = false
        values = [
          yamlencode({
            env = {
              AWS_REGION                = local.region
              AWS_DEFAULT_REGION        = local.region
              AWS_INTERMEDIATE_ROLE_ARN = dependency.eks-cluster.outputs.k8s_external_secrets_role_arn
            }
            securityContext = {
              fsGroup = 65534
            }
            serviceAccount = {
              annotations = {
                "eks.amazonaws.com/role-arn" = dependency.eks-cluster.outputs.k8s_external_secrets_role_arn
              }
            }
          })
        ]
      }]
    },
  }

  manifests_to_apply = {
    aws_aws_loadbalancer_controller = {
      path_pattern = "${get_parent_terragrunt_dir()}/../charts/aws-load-balancer-controller/*.yaml"
      vars = {
        role_arn = dependency.eks-cluster.outputs.aws_loadbalancer_controller_role_arn
      }
    }
  }
}
