terraform {
  source = ".///"
}


include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  tenant      = include.root.inputs.tenant
  environment = include.root.inputs.environment
}
