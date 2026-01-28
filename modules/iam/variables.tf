variable "region" {
  type = string
  description = "AWS Region to deploy resources"
}

variable "aws_account_id" {
  type = string
}

variable "services" {
  type = list(string)
}

variable "github_org" {
  type        = string
  description = "GitHub organization name"
  default     = "putit"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "putit-platform"
}
