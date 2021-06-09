variable "helm_release" {
  type = map(object({
    chart_name    = string
    namespace     = string
    chart_repo    = string
    chart_version = string
    deploy_config = map(object({
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
