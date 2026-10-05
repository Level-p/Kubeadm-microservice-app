# Main Terraform configuration for Kubernetes cluster
locals {
  cluster_name = "sept2026-kubadm"
  domain_name  = "mfon21.space"
}

# Wildcard certificate issued by the Jenkins stack
data "aws_acm_certificate" "cluster_cert" {
  domain      = local.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

module "cluster_vpc" {
  source = "./module/cluster-vpc"

  name     = local.cluster_name
  vpc_cidr = var.vpc_cidr
}

module "bastionhost" {
  source = "./module/bastionhost"

  name           = local.cluster_name
  vpc            = module.cluster_vpc.vpc_id
  public_subnets = module.cluster_vpc.public_subnet_ids
  privatekey     = module.cluster_vpc.private_key_pem
  keypair        = module.cluster_vpc.key_name
}

module "ansible" {
  source = "./module/ansible"

  name        = local.cluster_name
  vpc_id      = module.cluster_vpc.vpc_id
  key_name    = module.cluster_vpc.key_name
  bastion_sg  = module.bastionhost.bastion_sg_id
  subnet_id   = module.cluster_vpc.private_subnet_ids[0]
  privatekey  = module.cluster_vpc.private_key_pem
  bucket_name = var.bucket_name
  master1_ip  = module.master_nodes.master_private_ips[0]
  master2_ip  = module.master_nodes.master_private_ips[1]
  master3_ip  = module.master_nodes.master_private_ips[2]
  worker1_ip  = module.worker_nodes.worker_instance_ip[0]
  worker2_ip  = module.worker_nodes.worker_instance_ip[1]
  worker3_ip  = module.worker_nodes.worker_instance_ip[2]
  haproxy1_ip = module.haproxy.haproxy_private_ips[0]
  haproxy2_ip = module.haproxy.haproxy_private_ips[1]
}

module "haproxy" {
  source = "./module/haproxy"

  name       = local.cluster_name
  vpc        = module.cluster_vpc.vpc_id
  bastion-sg = module.bastionhost.bastion_sg_id
  ansible-sg = module.ansible.ansible_sg
  subnet_ids = module.cluster_vpc.public_subnet_ids
  keypair    = module.cluster_vpc.key_name
  master1-ip = module.master_nodes.master_private_ips[0]
  master2-ip = module.master_nodes.master_private_ips[1]
  master3-ip = module.master_nodes.master_private_ips[2]
  lb-sg-ids  = module.loadbalancer.lb_security_group_ids
}

module "master_nodes" {
  source = "./module/master-node"

  name               = local.cluster_name
  vpc_id             = module.cluster_vpc.vpc_id
  vpc_cidr           = module.cluster_vpc.vpc_cidr
  private_subnet_ids = module.cluster_vpc.private_subnet_ids
  master_count       = var.master_count
  instance_type      = var.instance_type
  key_name           = module.cluster_vpc.key_name
  bastion_sg_id      = module.bastionhost.bastion_sg_id
  ansible_sg_id      = module.ansible.ansible_sg
}

module "worker_nodes" {
  source = "./module/worker-nodes"

  name               = local.cluster_name
  vpc_id             = module.cluster_vpc.vpc_id
  private_subnet_ids = module.cluster_vpc.private_subnet_ids
  key_name           = module.cluster_vpc.key_name
  ansible_sg         = module.ansible.ansible_sg
  bastion_sg         = module.bastionhost.bastion_sg_id
}

module "loadbalancer" {
  source = "./module/loadbalancer"

  name            = local.cluster_name
  vpc_id          = module.cluster_vpc.vpc_id
  subnet_ids      = module.cluster_vpc.public_subnet_ids
  certificate_arn = data.aws_acm_certificate.cluster_cert.arn
  domain_name     = local.domain_name
  # target_ids      = module.worker_nodes.worker_instance_ip
  target_ids      = module.haproxy.haproxy_private_ips
}