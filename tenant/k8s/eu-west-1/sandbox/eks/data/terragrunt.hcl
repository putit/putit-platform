terraform {
  source = ".///"
}


include "root" {
  path   = find_in_parent_folders("root.hcl")
}

inputs = { 
  root_domain = "putit.io"
}
