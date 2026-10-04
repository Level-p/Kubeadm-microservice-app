variable "name" {
  type        = string
  description = "Name prefix for cluster resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the Kubernetes cluster VPC"
}