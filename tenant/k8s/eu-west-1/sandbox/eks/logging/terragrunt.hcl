terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/logging//"
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

dependency "monitoring" {
  config_path = "../monitoring"
}

inputs = {
  cluster_name             = dependency.eks-cluster.outputs.cluster_name
  cluster_oidc_provider_arn = dependency.eks-cluster.outputs.cluster_oidc_provider_arn
  environment              = local.environment
  namespace                = "logging"
  loki_storage_backend     = "filesystem"
  loki_retention           = "744h"
  loki_storage_size        = "50Gi"
  storage_class            = "gp3"
}
