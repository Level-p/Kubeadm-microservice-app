# Output the Cluster VPC ID
output "vpc_id" {
  description = "ID of the Kubernetes cluster VPC"
  value       = aws_vpc.cluster_vpc.id
}

# Output the Cluster VPC CIDR block
output "vpc_cidr" {
  description = "CIDR block of the Kubernetes cluster VPC"
  value       = aws_vpc.cluster_vpc.cidr_block
}

# Output Public Subnet IDs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.public_subnet_3.id
  ]
}

# Output Private Subnet IDs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]
}

# Output Internet Gateway ID
output "internet_gateway_id" {
  description = "ID of the Cluster VPC Internet Gateway"
  value       = aws_internet_gateway.cluster_igw.id
}

# Output the cluster key pair name
output "key_name" {
  description = "Name of the AWS key pair for the cluster nodes"
  value       = aws_key_pair.kubadm_key.key_name
}

# Output the cluster private key (used by the Ansible server to SSH to nodes)
output "private_key_pem" {
  description = "Private key for the cluster key pair"
  value       = tls_private_key.kubadm_key.private_key_pem
  sensitive   = true
}
