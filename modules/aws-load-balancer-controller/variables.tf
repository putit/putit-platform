variable "chart_version" {
  type = string
  default = "1.8.1"
}

variable "app_version" {
  type = string
  default = "v2.8.1"
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