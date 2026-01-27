terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/external-dns//"
}

locals {
  environment    = include.root.inputs.environment
  region         = include.root.inputs.region
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
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
  deploy                    = true
  chart_version             = "1.20.0"
  environment               = local.environment
  namespace                 = local.environment
  cluster_oidc_provider_arn = dependency.eks-cluster.outputs.cluster_oidc_provider_arn
  tenant                    = include.root.inputs.tenant
  hosted_zone_id            = dependency.data.outputs.public_route53_hosted_zone_id
  region                    = include.root.inputs.region
}
