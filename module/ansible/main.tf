# Security Group for Ansible Server
resource "aws_security_group" "ansible_sg" {
  name        = "${var.name}-ansible-sg"
  description = "Allow SSH access to Ansible server"
  vpc_id      = var.vpc_id

  ingress {
    description     = "ssh"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ansible-sg"
  }
}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Instance for Ansible server
resource "aws_instance" "ansible_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.s3-profile.name
  user_data = templatefile("${path.module}/userdata.sh", {
    privatekey  = var.privatekey,
    bucket_name = var.bucket_name,
    master1_ip  = var.master1_ip,
    master2_ip  = var.master2_ip,
    master3_ip  = var.master3_ip,
    worker1_ip  = var.worker1_ip,
    worker2_ip  = var.worker2_ip,
    worker3_ip  = var.worker3_ip,
    haproxy1_ip = var.haproxy1_ip,
    haproxy2_ip = var.haproxy2_ip,
  })

  tags = {
    Name = "${var.name}-ansible-server"
  }
}

# Upload Ansible playbooks directory to existing S3 bucket
resource "aws_s3_object" "playbooks" {
  for_each = fileset("${path.module}/playbook", "**/*")
  bucket   = var.bucket_name
  key      = "playbooks/${each.value}"
  source   = "${path.module}/playbook/${each.value}"
  etag     = filemd5("${path.module}/playbook/${each.value}")
}

# Create IAM role for S3
resource "aws_iam_role" "s3-role" {
  name = "ansible-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}
# Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "s3-policy" {
  role       = aws_iam_role.s3-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
# create IAM instance profile
resource "aws_iam_instance_profile" "s3-profile" {
  name = "ansible-s3-profile"
  role = aws_iam_role.s3-role.name
}