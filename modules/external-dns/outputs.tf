output "iam_role_arn" {
  description = "ARN of IAM role"
  value = module.irsa_role_external_dns.iam_role_arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       =  module.irsa_role_external_dns.iam_role_name
}
