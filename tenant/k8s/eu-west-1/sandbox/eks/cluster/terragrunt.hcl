terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/eks//"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  environment              = include.root.inputs.environment
  region           = include.root.inputs.region
  aws_account_id   = include.root.inputs.aws_account_id
  azs              = include.root.inputs.azs
  tenant              = include.root.inputs.tenant
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  environment          = local.environment
  cluster_name_prefix = "${local.tenant}-${local.environment}"
  cluster_version     = "1.30"
  private_subnets_ids = dependency.vpc.outputs.private_subnets_ids
  public_subnets_ids = dependency.vpc.outputs.public_subnets_ids
}
