locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  backend_vars = read_terragrunt_config(find_in_parent_folders("backend.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account_name        = local.account_vars.locals.account_name
  # for poc it's good, maybe later we will have multi tenant per single aws account
  tenant              = local.account_vars.locals.account_name
  aws_account_id          = local.account_vars.locals.aws_account_id

  region = local.region_vars.locals.region
  environment = local.env_vars.locals.environment

  backend_region         = local.backend_vars.locals.region
  backend_bucket         = local.backend_vars.locals.bucket
  backend_dynamodb_table = local.backend_vars.locals.dynamodb_table
  backend_encrypt        = local.backend_vars.locals.encrypt
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

# default provider versions
terraform {
   required_providers {
        aws = "~> 5.82"
        kubernetes = "~> 2.35"
        helm = "~> 2.17"
        argocd = {
          source = "oboukili/argocd"
          version = "~> 6.2"
        }
        kubectl = {
          source  = "gavinbunney/kubectl"
          version = "~> 1.18"
       }
    }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

provider "aws" {
  region  = "${local.region}"
  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.aws_account_id}"]
}

provider "argocd" {
  server_addr = "argocd.sandbox.k8s.putit.io:443"
  grpc_web    = true
  username    = "admin"
  password    = var.argocd_admin_password
}

variable "argocd_admin_password" {
  type      = string
  default   = ""
  sensitive = true
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = local.backend_encrypt
    bucket         = local.backend_bucket
    key            = format("%s/terraform.tfstate", path_relative_to_include())
    region         = local.backend_region
    dynamodb_table = local.backend_dynamodb_table
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.env_vars.locals
)
