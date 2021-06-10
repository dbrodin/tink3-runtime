output "cluster_id" {
  value = module.eks_cluster.cluster_id
}

output "cluster_oidc_issuer_url" {
  value = module.eks_cluster.cluster_oidc_issuer_url
}

output "aws_loadbalancer_controller_role_arn" {
  value = aws_iam_policy.aws_loadbalancer_controller_iam_policy.arn
}
