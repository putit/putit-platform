terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/traefik-ingress//"
}

locals {
  environment = include.root.inputs.environment
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

dependency "data" {
  config_path = "../data"
}

inputs = {
  cluster_name              = dependency.eks-cluster.outputs.cluster_name
  cluster_oidc_provider_arn = dependency.eks-cluster.outputs.cluster_oidc_provider_arn
  environment               = local.environment
  tenant                    = include.root.inputs.tenant
  all_cert_arns_string      = dependency.data.outputs.acm_wildcard_cert_arn
  chart_directory           = "${get_parent_terragrunt_dir()}/../charts/traefik//"
}
