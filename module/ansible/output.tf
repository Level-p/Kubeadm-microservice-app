output "ansible_server_public_ip" {
  description = "Public IP of the Ansible server"
  value       = aws_instance.ansible_server.public_ip
}

output "ansible_server_private_ip" {
  description = "Private IP of the Ansible server"
  value       = aws_instance.ansible_server.private_ip
}

output "ansible_sg" {
  value = aws_security_group.ansible_sg.id
}