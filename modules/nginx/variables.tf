variable "region" {
  type        = string
  description = "AWS Region to deploy resources"
}

variable "root_domain" {
  type        = string
  default     = "putit.io"
}

variable "namespace" {
  type        = string
  default     = "putit"
  description = "Namespace where the ArgoCD stack is installed."
}

variable "deploy" {
  type        = bool
  description = "Deploy argocd, by default set to false."
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
