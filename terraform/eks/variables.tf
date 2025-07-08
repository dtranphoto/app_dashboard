variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "k8-devops-dashboard"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
  default     = "vpc-0b02dde4d7fbd4d60"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = [
    "subnet-074ed09585fbaccb7",  # us-west-2a
    "subnet-0ce900d5a1014802b",  # us-west-2c
    "subnet-07ee473a38be3bd62"   # us-west-2d
  ]
}
