terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/vpc//"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  environment      = include.root.inputs.environment
  region           = include.root.inputs.region
  aws_account_id   = include.root.inputs.aws_account_id
  azs              = include.root.inputs.azs
  tenant           = include.root.inputs.tenant
}

inputs = {
  name         = "vpc-${local.environment}"
  cluster_name = "${local.tenant}-${local.environment}"
  cidr = "10.42.0.0/16"

  azs             = local.azs
  private_subnets = ["10.42.1.0/24", "10.42.2.0/24", "10.42.3.0/24"]
  public_subnets  = ["10.42.101.0/24", "10.42.102.0/24", "10.42.103.0/24"]
  database_subnets = ["10.42.11.0/24", "10.42.12.0/24", "10.42.13.0/24"]
  database_subnet_group_name = "commonprefix-${local.environment}"

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Owner       = "local.aws_account_id"
    Environment = local.environment
  }

  vpc_tags = {
    Name = "vpc-${local.environment}"
  }
}
