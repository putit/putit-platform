# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = basename("${get_terragrunt_dir()}")
  aws_account_id = "${get_aws_account_id()}"
  tenant = local.account_name
  root_domain = "putit.io"
}
