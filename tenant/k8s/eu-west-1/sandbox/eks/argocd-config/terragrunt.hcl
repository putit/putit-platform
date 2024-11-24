terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/argocd-config//"
}

locals {
  environment    = include.root.inputs.environment
  region         = include.root.inputs.region
  aws_account_id = include.root.inputs.aws_account_id
}

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose         = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

dependency "argocd-server" {
  config_path = "../argocd-server"
}

inputs = { 
  cluster_name            = dependency.eks-cluster.outputs.cluster_name
  cluster_endpoint        = dependency.eks-cluster.outputs.cluster_endpoint
  argocd_web_url          = dependency.argocd-server.outputs.argocd_web_url
  argocd_namespace        = dependency.argocd-server.outputs.argocd_namespace
  environment             = local.environment
  environments_list       = [local.environment]
  default_namespace_target = "technipfmc"
  app_repo_url            = "git@github.com:tfmcdigital/k8s-poc-demo-app.git"
  target_revision         = "HEAD"
}
