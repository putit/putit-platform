variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
}

variable "environment" {
  type = string
}

variable "namespace" {
  type    = string
  default = "logging"
}

variable "loki_chart_version" {
  type    = string
  default = "6.16.0"
}

variable "alloy_chart_version" {
  type    = string
  default = "0.9.2"
}

variable "loki_storage_backend" {
  type        = string
  default     = "filesystem"
  description = "Storage backend for Loki: 'filesystem' or 's3'"
}

variable "loki_s3_bucket" {
  type    = string
  default = ""
}

variable "loki_s3_region" {
  type    = string
  default = "eu-west-1"
}

variable "loki_retention" {
  type    = string
  default = "744h"
  description = "Log retention period (default 31 days)"
}

variable "loki_storage_size" {
  type    = string
  default = "50Gi"
}

variable "storage_class" {
  type    = string
  default = "gp3"
}

variable "cluster_oidc_provider_arn" {
  type    = string
  default = ""
}
