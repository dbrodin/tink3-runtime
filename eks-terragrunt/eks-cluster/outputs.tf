output "cluster_id" {
  value = module.eks_cluster.cluster_id
}

output "cluster_oidc_issuer_url" {
  value = module.eks_cluster.cluster_oidc_issuer_url
}
