variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
}

variable "environment" {
  type = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "chart_version" {
  type        = string
  default     = "65.3.1"
  description = "kube-prometheus-stack Helm chart version"
}

variable "grafana_admin_password" {
  type        = string
  default     = "admin"
  sensitive   = true
  description = "Grafana admin password. Change after first login."
}

variable "grafana_ingress_enabled" {
  type    = bool
  default = false
}

variable "grafana_host" {
  type    = string
  default = ""
}

variable "storage_class" {
  type    = string
  default = "gp3"
}

variable "prometheus_retention" {
  type    = string
  default = "15d"
}

variable "prometheus_storage_size" {
  type    = string
  default = "50Gi"
}

variable "grafana_storage_size" {
  type    = string
  default = "10Gi"
}

variable "loki_url" {
  type        = string
  default     = "http://loki.logging.svc:3100"
  description = "Loki endpoint for Grafana datasource"
}
