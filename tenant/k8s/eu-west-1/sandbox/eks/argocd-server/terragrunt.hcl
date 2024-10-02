terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/argocd-server//"
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

dependency "traefik-ingress" {
  config_path = "../traefik-ingress"
}

inputs = { 
  cluster_name            = dependency.eks-cluster.outputs.cluster_name
  environment = local.environment 
  tenant = include.root.inputs.tenant
  chart_version = "5.55.0"
  deploy = true
  pub_ingress_hostname = dependency.traefik-ingress.outputs.pub_ingress_hostname
}
