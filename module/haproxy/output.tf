output "haproxy_private_ips" {
  value = aws_instance.HAProxy-server[*].private_ip
}

output "haproxy_instance_ids" {
  value = aws_instance.HAProxy-server[*].id
}
