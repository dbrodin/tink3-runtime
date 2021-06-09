variable "helm_release" {
  type        = map(string)
  default     = {}
  description = "Configuratoin for the helm deployment"
}

variable "kubernetes_network_policy" {
  type        = list(any)
  default     = []
  description = "Defined network policy for the helm deployment"
}
