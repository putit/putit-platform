# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  region         = "eu-west-1"
  bucket         = "platform-k8s-gw-poc-tf-state-${get_aws_account_id()}"
  #bucket         = "${basename(get_repo_root())}-tf-state-${get_aws_account_id()}"
  #dynamodb_table = "${basename(get_repo_root())}-tf-state-${get_aws_account_id()}"
  dynamodb_table = "platform-k8s-gw-poc-tf-state-${get_aws_account_id()}"
  
  encrypt        = true
  disable_bucket_update  = true
  skip_bucket_versioning = true
}
