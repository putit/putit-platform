module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"  # pin to 5.x — v6.0+ requires AWS provider v6

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets    = var.database_subnets
  database_subnet_group_name = var.database_subnet_group_name

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_ipv6        = var.enable_ipv6
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  public_subnet_tags = {
    Name      = "public-subnet"
    Terraform = "true"
  }

  private_subnet_tags = {
    Name                       = "private-subnet"
    Terraform                  = "true"
    "karpenter.sh/discovery"   = var.cluster_name
  }
}