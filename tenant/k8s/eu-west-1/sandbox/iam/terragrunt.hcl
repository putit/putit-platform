terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/iam//"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose = true
}

locals {
  region           = include.root.inputs.region
  aws_account_id   = include.root.inputs.aws_account_id
}

inputs = {
  region = include.root.inputs.region
  aws_account_id = include.root.inputs.aws_account_id
  services = ["nginx", "k8s-poc-demo-app"]
}
