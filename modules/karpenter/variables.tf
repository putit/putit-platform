variable "region" {
  type        = string
  description = "AWS Region to deploy resources"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Namespace where the secret manager csi stack is installed."
}

variable "deploy" {
  type        = bool
  description = "Deploy secret manager csi, by default set to false."
  default     = false
}

variable "chart_version" {
  type        = string
  description = "Chart version for argocd"
  default     = "1.0.0"
}

variable "environment" {
  type = string
}

variable "tenant" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "Base EKS Cluster name (final name is {var.cluster_name}-{environment})"
}

variable "chart_directory" {
  type = string
}

variable "cluster_oidc_provider_arn" {
  type        = string
  description = "OIDC provider arn"
}

variable "karpenter_instance_types" {
  type        = list(string)
  default     = ["t3.large", "t3.xlarge"]
  description = "Instance types allowed for Karpenter NodePool"
}

variable "karpenter_cpu_limit" {
  type        = string
  default     = "120"
  description = "CPU limit for Karpenter NodePool"
}

variable "karpenter_memory_limit" {
  type        = string
  default     = "120Gi"
  description = "Memory limit for Karpenter NodePool"
}