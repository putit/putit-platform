terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/rds//"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"
}

locals {
  environment      = include.root.inputs.environment
  region           = include.root.inputs.region
  aws_account_id   = include.root.inputs.aws_account_id
  azs              = include.root.inputs.azs
  tenant           = include.root.inputs.tenant

}

inputs = {
  db_name         = "commonprefix-${local.environment}"
  vpc_cidr_block = "10.42.0.0/16"
  vpc_id = dependency.vpc.outputs.vpc_id
  database_subnets_id = dependency.vpc.outputs.database_subnets_id
  db_subnet_group_name = dependency.vpc.outputs.database_subnet_group_name
  environment = local.environment

  tags = {
    Owner       = "local.aws_account_id"
    Environment = local.environment
  }

}
