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
  default     = "argocd"
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
  default     = "7.6.12"
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

variable "pub_ingress_hostname" {
  type = string
  description = "Hostname for the public ingress domain, used by external-dns provided by traefik."
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID for ArgoCD repo access."
  default     = ""
}

variable "github_app_installation_id" {
  type        = string
  description = "GitHub App Installation ID for ArgoCD repo access."
  default     = ""
}

variable "github_org" {
  type        = string
  description = "GitHub organization name."
  default     = "putit"
}

variable "github_app_private_key_secret_name" {
  type        = string
  description = "AWS Secrets Manager secret name containing the GitHub App private key."
  default     = ""
}
