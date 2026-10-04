output "vpc_id" {
  value = module.cluster_vpc.vpc_id
}

output "bastion_asg_name" {
  value = module.bastionhost.bastion_asg_name
}

output "ansible_server_private_ip" {
  value = module.ansible.ansible_server_private_ip
}

output "haproxy_private_ips" {
  value = module.haproxy.haproxy_private_ips
}

output "master_private_ips" {
  value = module.master_nodes.master_private_ips
}

output "worker_private_ips" {
  value = module.worker_nodes.worker_instance_ip
}
