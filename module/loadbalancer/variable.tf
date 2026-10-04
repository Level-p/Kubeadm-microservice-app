variable "domain_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "target_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}