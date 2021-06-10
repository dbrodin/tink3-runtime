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
  force_update    = try(each.value["deploy_config"]["force_helm_update"], false)
  recreate_pods   = try(each.value["deploy_config"]["recreate_pods_during_update"], false)
  wait            = try(each.value["deploy_config"]["wait_for_rollout"], true)
  cleanup_on_fail = try(each.value["deploy_config"]["cleanup_on_fail"], false)

  skip_crds = try(each.value["deploy_config"]["skip_crds"], false)
  verify    = try(each.value["deploy_config"]["verify"], false)

  values = try(each.value["deploy_config"]["values"], [])
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

## Kubectl release
data "kubectl_path_documents" "manifests" {
  for_each = var.manifests_to_apply

  # Example ../file to chart..
  pattern = each.value["path_pattern"]
  vars    = lookup(each.value, "vars", {})
}

resource "kubectl_manifest" "applying_file_manifest" {
  for_each  = data.kubectl_path_documents.manifests
  yaml_body = try(lookup(each.value, "documents", [])[0], "")
}

# Can do inline as well..
resource "kubectl_manifest" "applying_inline_manifest" {
  count     = var.inline_yaml_manifest != "" ? var.inline_yaml_manifest : 0
  yaml_body = yamldecode(var.inline_yaml_manifest)
}
