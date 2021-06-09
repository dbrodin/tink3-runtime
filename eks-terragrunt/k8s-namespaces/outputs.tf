output "k8s_namespaces" {
  value = {
    for name, meta in kubernetes_namespace.ns : name => meta
  }
}
