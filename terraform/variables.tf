variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
  default     = "386503255039"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "lucid-dashboard"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = [
    "subnet-01689f80cd3d0b490",
    "subnet-0ce900d5a1014802b",
    "subnet-074ed09585fbaccb7",
    "subnet-07ee473a38be3bd62"
  ]
}

variable "security_group_id" {
  description = "Security group for ECS tasks"
  type        = string
  default     = "sg-079645811790ebad6"
}