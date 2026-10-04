data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# IAM role so masters can be reached with SSM Session Manager
resource "aws_iam_role" "master_role" {
  name = "${var.name}-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "master_ssm" {
  role       = aws_iam_role.master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "master_profile" {
  name = "${var.name}-master-profile"
  role = aws_iam_role.master_role.name
}

resource "aws_security_group" "master_sg" {
  name        = "${var.name}-master-sg"
  description = "Kubernetes control plane"
  vpc_id      = var.vpc_id

  # API server: HAProxy, workers and other masters
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd between masters
  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  # kubelet, controller manager, scheduler
  ingress {
    description = "Control plane components"
    from_port   = 10250
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Calico BGP between nodes (remove if the team uses a different CNI)
  ingress {
    description = "Calico BGP"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH from bastion, only if a bastion is given
  dynamic "ingress" {
    for_each = var.bastion_sg_id == null ? [] : [1]
    content {
      description     = "SSH from bastion"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [var.bastion_sg_id]
    }
  }

  # SSH from the Ansible server, which runs the kubeadm playbooks
  dynamic "ingress" {
    for_each = var.ansible_sg_id == null ? [] : [1]
    content {
      description     = "SSH from Ansible"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [var.ansible_sg_id]
    }
  }

  # Weave Net CNI (deployed by kubectl.yml)
  ingress {
    description = "Weave Net control"
    from_port   = 6783
    to_port     = 6783
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Weave Net data"
    from_port   = 6783
    to_port     = 6784
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-master-sg"
  }
}

resource "aws_instance" "master" {
  count                  = var.master_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnet_ids, count.index)
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.master_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.master_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name}-master-${count.index + 1}"
    Role = "master"
  }
}