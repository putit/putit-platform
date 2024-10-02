output "cluster_name" {
  value = module.eks.cluster_name
  description = "EKS Cluster ID to be used for kubernetes connection in other Automation scripts"
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
  description = "EKS Cluster ID to be used for kubernetes connection in other Automation scripts"
}

output "main_namespace" {
  value = var.main_namespace
  description = "Main project namespace"
}

output "worker_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider arn"
  value = module.eks.oidc_provider_arn
}
