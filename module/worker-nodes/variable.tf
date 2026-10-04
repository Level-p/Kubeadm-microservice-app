variable "name" {
  type = string
}
variable "key_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "bastion_sg" {
  description = "Security Group ID of the Bastion Host"
  type        = string
}
variable "ansible_sg" {
  description = "Security Group ID of the Ansible Control Node"
  type        = string
}