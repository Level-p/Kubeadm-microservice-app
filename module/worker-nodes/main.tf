# Terraform script to provision three EC2 instances configured as Kubernetes Worker Nodes
# across three Availability Zones in the eu-west-1 region.


# Data Sources - Fetch the most recent Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


# Create Security Group for Worker Nodes

resource "aws_security_group" "worker_nodes_sg" {
  name        = "${var.name}-worker-nodes-sg"
  description = "Security group for Kubernetes Worker Nodes"
  vpc_id      = var.vpc_id

  # Ingress Rule 1: Kubelet API (10250)
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Ingress Rule 2: Kube-proxy metrics/health check (10256)
  ingress {
    description = "Kube-proxy metrics/health check"
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Ingress Rule 3a: CNI Overlay Network (Weave Net control port) - TCP
  ingress {
    description = "weave net CNI"
    from_port   = 6783
    to_port     = 6783
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  #Ingress Rule 3b: Weave Net Data Plane (UDP)
  ingress {
    description = "Weave Net Data & Neighbor Discovery"
    from_port   = 6783
    to_port     = 6784
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  # Ingress Rule 4: Cluster DNS (CoreDNS) - UDP
  ingress {
    description = "Cluster DNS (UDP 53)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress Rule 5: NodePort Services (30000-32767)
  ingress {
    description = "NodePort Range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress Rule 6: SSH Access (For Bastion Host access)
  ingress {
    description     = "SSH Access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg, var.ansible_sg]
  }

  # Egress Rule: Allow all outbound traffic (Needed for image pulls/updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-Worker-Nodes-SG"
  }
}


# Create 3 EC2 instances, one in each of the specific private subnets
resource "aws_instance" "worker_node" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  subnet_id              = var.private_subnet_ids[count.index]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.worker_nodes_sg.id]
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  tags = {
    Name = "${var.name}-worker-node-${count.index + 1}"
  }
}