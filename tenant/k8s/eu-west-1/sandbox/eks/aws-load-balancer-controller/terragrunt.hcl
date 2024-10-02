terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/aws-loadbalanbcer-controller"
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
  # make sure in module there is a matching IAM policy
  chart_version = "1.8.1"
  app_version = "v2.8.1"
  namespace = "ingress"
}