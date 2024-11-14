module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets

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
    "karpenter.sh/discovery"   = "k8s-sandbox-sandbox"
  }
}