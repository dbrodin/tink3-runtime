locals {
  # Define all namespaces
  namespaces = {
    for name, config in var.namespace_config :
    name => config
  }
}

# Create the namespaces
resource "kubernetes_namespace" "ns" {
  for_each = local.namespaces

  metadata {
    name        = each.key
    labels      = lookup(each.value, "labels", {})
    annotations = lookup(each.value, "annotations", {})
  }
}
