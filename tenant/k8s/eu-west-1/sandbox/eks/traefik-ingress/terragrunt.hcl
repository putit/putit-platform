terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/traefik-ingress//"
}

locals {
  environment        = include.root.inputs.environment
  region        = include.root.inputs.region
  aws_account_id = include.root.inputs.aws_account_id
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

inputs = { 
  cluster_name            = dependency.eks-cluster.outputs.cluster_name
  cluster_oidc_provider_arn = dependency.eks-cluster.outputs.cluster_oidc_provider_arn
  environment = local.environment 
  tenant = include.root.inputs.tenant
  traefik_chart_version = "20.8.0"
  # TODO: replace with data.aws_acm_certificate lookup or pass from dependency
  all_cert_arns_string = "arn:aws:acm:${local.region}:${local.aws_account_id}:certificate/${get_env("ACM_CERTIFICATE_ID", "636f0703-c9a7-4aa4-93a8-a289786bc666")}"
  chart_directory = "${get_parent_terragrunt_dir()}/../charts/traefik//"
}
