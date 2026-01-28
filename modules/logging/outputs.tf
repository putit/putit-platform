output "loki_endpoint" {
  value = "http://loki.${var.namespace}.svc:3100"
}

output "namespace" {
  value = var.namespace
}
