output "argocd_web_url" {
  description = "Publiczny URL interfejsu webowego ArgoCD"
  value       = local.web_domain
}

output "argocd_grpc_url" {
  description = "Publiczny URL endpointu gRPC ArgoCD"
  value       = local.argocd_grpc_domain
}

output "argocd_namespace" {
  description = "Namespace, w którym działa ArgoCD"
  value       = var.namespace
}