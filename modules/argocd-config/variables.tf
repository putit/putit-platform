variable "region" {
  type = string
  description = "AWS Region to deploy resources"
  default = "eu-west-1"
}

variable "cluster_name" {
  type    = string
  description = "Base EKS Cluster name (final name is {var.cluster_name}-{environment})"
}

variable "argocd_namespace" {
  type    = string
  default = "argocd"
  description = "Namespace where the ArgoCD stack is installed."
}

variable "environments_list" {
  type = list(string)
  description = "List of env which are going to be covered by this argocd instance."
}

variable "environment" {
  type = string
}

variable "tenant" {
  type = string
}

variable "default_namespace_target" {
  type = string
  default = "technipfmc"
  description = "Default namespace, which is going to be a target for registered apps."
}

variable "app_repo_url" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "target_revision" {
  type = string
}
