# Can run from path if not defined in a helm repo
# resource "helm_release" "example" {
#   name  = "my-local-chart"
#   chart = "./.charts/example"
# }

resource "helm_release" "main" {
  for_each = var.helm_release
  # Helm specifics
  name       = lookup(each.value, "chart_name", null)
  namespace  = lookup(each.value, "namespace", null)
  repository = lookup(each.value, "chart_repo", null)
  chart      = lookup(each.value, "chart_name", null)
  version    = lookup(each.value, "chart_version", null)

  # Deploy config
  force_update    = lookup(each.value, "force_helm_update", false)
  recreate_pods   = lookup(each.value, "recreate_pods_during_update", false)
  wait            = lookup(each.value, "wait_for_rollout", true)
  cleanup_on_fail = lookup(each.value, "cleanup_on_fail", false)

  skip_crds = lookup(each.value, "skip_crds", false)
  verify    = lookup(each.value, "verify", false)

  values = lookup(each.value, "values", [])
}

# TODO: This could be checked and fixed with the ingress/egress etc
resource "kubernetes_network_policy" "main" {
  for_each = var.kubernetes_network_policy

  metadata {
    name      = lookup(each.value["metadata"], "name", null)
    namespace = lookup(each.value["metadata"], "namespace", null)
  }

  dynamic "spec" {
    for_each = lookup(each.value, "spec", [])

    content {
      dynamic "pod_selector" {
        for_each = lookup(spec.value, "pod_selector", {})

        content {
          match_expressions {
            key      = lookup(spec.value, "key", null)
            operator = lookup(spec.value, "operator", null)
            values   = lookup(spec.value, "operator", [])
          }
        }
      }

      # Create dynamic for Ingress

      # Create dynamic for Egress

      policy_types = lookup(spec.value, "policy_types", null)
    }
  }

  # spec {
  #   pod_selector {
  #     match_expressions {
  #       key      = "name"
  #       operator = "In"
  #       values   = ["namespace"]
  #     }
  #   }

  #   ingress {
  #     ports {
  #       port     = "http"
  #       protocol = "TCP"
  #     }
  #     ports {
  #       port     = "https"
  #       protocol = "TCP"
  #     }

  #     dynamic "from" {
  #       for_each = ["ingress_cidrs"]
  #       content {
  #         ip_block {
  #           cidr = from.value
  #         }
  #       }
  #     }
  #   }

  #   policy_types = ["Ingress"]
  # }
}
