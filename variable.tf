variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the Kubernetes cluster VPC"
  default     = "10.0.0.0/16"
}

variable "bucket_name" {
  type        = string
  description = "Existing S3 bucket the Ansible playbooks are uploaded to"
  default     = "mfon21-kubadm-state-s3bucket"
}

variable "master_count" {
  type        = number
  description = "Number of control plane nodes (the Ansible inventory expects 3)"
  default     = 3
}

variable "instance_type" {
  type        = string
  description = "Instance type for the control plane nodes"
  default     = "t3.medium"
}
