variable "helm_release" {
  type = map(object({
    chart_name    = string
    chart         = string
    namespace     = string
    chart_repo    = string
    chart_version = string
    deploy_config = list(object({
      force_helm_update           = bool
      recreate_pods_during_update = bool
      wait_for_rollout            = bool
      cleanup_on_fail             = bool
      skip_crds                   = bool
      verify                      = bool
      values                      = list(string)
    }))
  }))
  default     = {}
  description = "Configuration for the helm deployment"
}

variable "kubernetes_network_policy" {
  type        = set(any)
  default     = []
  description = "Defined network policy for the helm deployment"
}

variable "manifests_to_apply" {
  type = map(object({
    path_pattern = string
    vars         = map(string)
  }))
  default     = {}
  description = "Read inputs from path_pattern: ./charts/*.yaml to apply from yaml file"
}

variable "inline_yaml_manifest" {
  type        = string
  default     = ""
  description = "Inline yaml to apply"
}
