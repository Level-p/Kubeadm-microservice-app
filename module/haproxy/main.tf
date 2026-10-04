# Data source to get the latest RedHat AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#Creating haproxy server security group
resource "aws_security_group" "haproxy-sg" {
  name        = "${var.name}haproxy-sg"
  description = "Allow ssh"
  vpc_id      = var.vpc

  ingress {
    description     = "sshport"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion-sg, var.ansible-sg]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Internal only
  }

  ingress {
    description     = "HTTPS from load balancers"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.lb-sg-ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-haproxy-sg"
  }
}

#Creating haproxy server
resource "aws_instance" "HAProxy-server" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id #ubuntu
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.haproxy-sg.id]
  key_name               = var.keypair
  subnet_id              = element(var.subnet_ids, count.index)
  user_data = templatefile("${path.module}/haproxy-userdata.sh", {
    nr_key    = "",
    nr_acc_id = 6496342,
    master1   = var.master1-ip,
    master2   = var.master2-ip,
    master3   = var.master3-ip
  })

  # Use the local variable for user data
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  metadata_options {
    http_tokens = "required"
  }
  tags = {
    Name = "${var.name}-haproxy-server-${count.index + 1}"
  }
}