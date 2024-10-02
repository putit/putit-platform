variable "namespaces" {
  description = "A list of namespaces to create"
  type        = list(string)
  default     = ["putit"]
}

variable "cluster_name" {
  type        = string
  description = "Base EKS Cluster name (final name is {var.cluster_name}-{environment})"
}
