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
