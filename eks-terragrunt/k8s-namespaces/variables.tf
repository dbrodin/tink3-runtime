variable "namespace_config" {
  type        = map(map(map(string)))
  description = "Namespace config from config file"
}

variable "cluster_id" {
  type = string
}
