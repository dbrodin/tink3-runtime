variable "cluster_config" {
  type = object({
    cluster_name    = string
    cluster_version = string
    tags            = map(string)
    map_roles       = list(map(string))
  })
  description = "Cluster config - config.yaml inputs"
}

variable "vpc_id" {
  type        = string
  description = "VPC to deploy EKS Cluster in"
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnets to run EKS in"
}
