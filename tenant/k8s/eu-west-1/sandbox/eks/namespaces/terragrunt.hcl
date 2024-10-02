terraform {
  source  = "${get_parent_terragrunt_dir()}/../modules/k8s-namespaces//"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks-cluster" {
  config_path = "../cluster"
}

inputs = {
  default_namespace = [include.root.inputs.environment]
  cluster_name            = dependency.eks-cluster.outputs.cluster_name
}
