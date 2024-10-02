variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS Region to deploy resources"
}

variable "tenant" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "Base EKS Cluster name (final name is {var.cluster_name}-{environment})"
}

variable "traefik_namespace" {
  type        = string
  default     = "traefik"
  description = "Namespace where the Traefik stack is installed."
}

variable "deploy_traefik" {
  type        = bool
  description = "Deploy traefik, by default set to false."
  default     = true
}

variable "traefik_chart_version" {
  type        = string
  description = "Helm chart version for traefik."
  default     = "20.8.0"
}

variable "root_domain" {
  type        = string
  default     = "putit.io"
}

variable "all_cert_arns_string" {
  type = string
  default = "All arns for certs as a string."
}

variable "chart_directory" {
  type = string
}

variable "cluster_oidc_provider_arn" {
  type = string
}
