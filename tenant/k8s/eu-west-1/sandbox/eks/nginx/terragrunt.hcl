terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/nginx//"
}

#locals {
#  environment        = include.root.inputs.environment
#  region        = include.root.inputs.region
#  aws_account_id = include.root.inputs.aws_account_id
#}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  #expose = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

inputs = { 
  cluster_name            = dependency.eks-cluster.outputs.cluster_name
  #environment = local.environment 
  environment = "sandbox"
  #tenant = include.root.inputs.tenant
  tenant = "k8s"
  chart_version = "15.14.0"
  chart_directory = "${get_parent_terragrunt_dir()}/../charts/nginx//"
  deploy = true
}
