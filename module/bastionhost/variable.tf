variable "name" {}
variable "vpc" {}
variable "public_subnets" {
  type        = list(string)
  description = "List of subnet IDs for the bastion ASG"
}
