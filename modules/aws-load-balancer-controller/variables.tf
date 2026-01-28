variable "chart_version" {
  type = string
  default = "3.0.0"
}

variable "app_version" {
  type = string
  default = "v3.0.0"
  description = "Should match version for the chart."
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  type = string
  default = "ingress"
}

variable "cluster_oidc_provider_arn" {
  type = string
}