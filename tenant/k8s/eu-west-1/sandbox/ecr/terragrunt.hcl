terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/ecr//"
}

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose         = true
}

inputs = {
  app_names = []  # Apps are auto-created by GitHub Actions workflow
}
