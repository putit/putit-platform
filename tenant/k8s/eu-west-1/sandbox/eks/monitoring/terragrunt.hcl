terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/monitoring//"
}

locals {
  environment    = include.root.inputs.environment
  region         = include.root.inputs.region
  aws_account_id = include.root.inputs.aws_account_id
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

dependency "namespaces" {
  config_path = "../namespaces"
}

inputs = {
  cluster_name    = dependency.eks-cluster.outputs.cluster_name
  environment     = local.environment
  namespace       = "monitoring"
  chart_version   = "65.3.1"
  prometheus_retention    = "15d"
  prometheus_storage_size = "50Gi"
  grafana_storage_size    = "10Gi"
  storage_class           = "gp3"
}
