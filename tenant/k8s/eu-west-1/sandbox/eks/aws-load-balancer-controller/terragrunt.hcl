terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/aws-load-balancer-controller"
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
  chart_version = "3.0.0"
  app_version = "v3.0.0"
  namespace = "ingress"
}