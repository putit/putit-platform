variable "environment" {
  type = string
}

variable "region" {
  type = string
  default = "eu-west-1"
}

variable "tenant" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "Base EKS Cluster name (final name is {var.cluster_name}-{environment})"
}

variable "namespace" {
  type        = string
  default     = "ingress"
  description = "Default namespace for the service account for external-dns."
}

variable "cluster_oidc_provider_arn" {
  type = string
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for traefik."
  default     = "9.0.3"
}

variable "deploy" {
  type        = bool
  description = "Deploy argocd, by default set to false."
  default     = false
}

variable "root_domain" {
  type        = string
  default     = "putit.io"
}

variable "hosted_zone_id" {
  type = string
}
