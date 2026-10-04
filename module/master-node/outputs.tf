output "master_private_ips" {
  value = aws_instance.master[*].private_ip
}

output "master_instance_ids" {
  value = aws_instance.master[*].id
}

output "master_sg_id" {
  value = aws_security_group.master_sg.id
}