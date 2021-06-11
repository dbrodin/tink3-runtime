locals {
  cluster_name    = var.cluster_config["cluster_name"]
  cluster_version = var.cluster_config["cluster_version"]
  common_tags     = var.cluster_config["tags"]
  map_roles       = var.cluster_config["map_roles"]
}

module "eks_cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v17.0.3"

  cluster_name     = local.cluster_name
  cluster_version  = local.cluster_version
  subnets          = var.private_subnets
  vpc_id           = var.vpc_id
  tags             = local.common_tags
  write_kubeconfig = true
  enable_irsa      = true
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    local.cluster_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  # IAM Mappings for roles to get access:
  # Managed from the root config.yaml file
  # Example:
  # {
  #   rolearn  = "arn:aws:iam::66666666666:role/role1"
  #   username = "role1"
  #   groups   = ["system:masters"]
  # },
  map_roles = local.map_roles

  # TODO: Create this as a more dynamic fargate profiles input from root config
  fargate_profiles = {
    "default" = {
      selectors = [
        {
          namespace = "dummy-namespace"
          labels = {
            fargate-default = "true"
          }
        }
      ]
    }
  }

  # TODO: Create this as a more dynamic node_groups input from root config
  node_groups = {
    "spot" = {
      create_launch_template = true
      desired_capacity       = 3
      max_capacity           = 5
      min_capacity           = 1
      instance_types         = ["t3.small"]
      disk_size              = 16
      k8s_labels = {
        pool = "spot-instances"
      }
      capacity_type = "SPOT"
    }
  }
}

# Add addons to the cluster
resource "aws_eks_addon" "cni" {
  cluster_name      = module.eks_cluster.cluster_id
  resolve_conflicts = "OVERWRITE"
  addon_name        = "vpc-cni"
  addon_version     = "v1.7.10-eksbuild.1"
  tags              = local.common_tags
}

resource "aws_eks_addon" "dns" {
  cluster_name      = module.eks_cluster.cluster_id
  resolve_conflicts = "OVERWRITE"
  addon_name        = "coredns"
  addon_version     = "v1.8.3-eksbuild.1"
  tags              = local.common_tags
}
