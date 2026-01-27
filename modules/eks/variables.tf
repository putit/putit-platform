variable "environment" {
  type = string
}

variable "region" {
  type = string
  description = "AWS Region to deploy resources"
}

variable "private_subnets_ids" {
  type = list(string)
}

variable "public_subnets_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "cluster_name_prefix" {
  type    = string
  default = "eks-app"
  description = "Base EKS Cluster name (final name is {var.cluster_name_prefix}-{environment})"
}

variable "main_namespace" {
  type    = string
  default = "putit"
  description = "Namespace to be used for the project. Created automatically by the module."
}

variable "workers_min_sizing" {
  type    = number
  default = 1
  description = "Auto scaling options: Minimum amount of EKS Workers"
}

variable "workers_max_sizing" {
  type    = number
  default = 1
  description = "Auto scaling options: Maximum amount of EKS Workers"
}

 variable "workers_instance_type" {
  type    = string
  default = "c6a.xlarge"
  description = "EC2 Instance Type to be used for workers."
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "EKS Worker Nodes VM Image ID. Leave empty to auto-detect latest EKS-optimized AMI via SSM."
}

variable "cluster_version" {
  type = string
  description = "EKS cluster version."
}

variable "aws_loadbalancer_controller_chart_version" {
  type = string
  description = "aws-lb-controller chart version. https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/Chart.yaml"
  default = "1.2.3"
}

variable "aws_loadbalancer_controller_app_version" {
  type = string
  default = "v2.7.1"
  description = "Should match version for the chart."
}
