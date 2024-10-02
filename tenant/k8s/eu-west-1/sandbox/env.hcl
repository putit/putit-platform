# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  # that will get env name
  environment              = basename("${get_terragrunt_dir()}")
}
