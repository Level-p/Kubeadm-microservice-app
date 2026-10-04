locals {
  name = "sept2026-kubadm"
}

# Creating VPC for Jenkins
resource "aws_vpc" "sept2026_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${local.name}-vpc"
  }
}

# Internet gateway for Jenkins VPC
resource "aws_internet_gateway" "sept2026_igw" {
  vpc_id = aws_vpc.sept2026_vpc.id

  tags = {
    Name = "${local.name}-igw"
  }
}

# Public subnet 1
resource "aws_subnet" "sept2026_public_subnet_1" {
  vpc_id            = aws_vpc.sept2026_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${local.name}_public_subnet_1"
  }
}

# Public subnet 2
resource "aws_subnet" "sept2026_public_subnet_2" {
  vpc_id            = aws_vpc.sept2026_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${local.name}_public_subnet_2"
  }
}

# Public subnet 3
resource "aws_subnet" "sept2026_public_subnet_3" {
  vpc_id            = aws_vpc.sept2026_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "${local.name}_public_subnet_3"
  }
}

# Creating route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.sept2026_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sept2026_igw.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

# Associating route table with public subnet
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.sept2026_public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.sept2026_public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  subnet_id      = aws_subnet.sept2026_public_subnet_3.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for Jenkins Application Load Balancer
resource "aws_security_group" "jenkins_alb_sg" {
  name        = "${local.name}-jenkins-alb-sg"
  description = "Security group for Jenkins Application Load Balancer"
  vpc_id      = aws_vpc.sept2026_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-jenkins-alb-sg"
  }
}

# Security group for Jenkins EC2 server
resource "aws_security_group" "jenkins_sg" {
  name        = "${local.name}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.sept2026_vpc.id

  # Allow Jenkins traffic only from the Application Load Balancer
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-jenkins-sg"
  }
}

# Terraform state access policy
resource "aws_iam_policy" "terraform_state_access" {
  name        = "terraform-state-access"
  description = "Allows authorized Terraform users to access the Terraform state bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::sept2026-kubadm-state-s3bucket"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::sept2026-kubadm-state-s3bucket/*"
      }
    ]
  })
}

# Generate SSH private/public key pair
resource "tls_private_key" "kubadm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register public key with AWS
resource "aws_key_pair" "kubadm_key" {
  key_name   = "Sept2026-kubadm-key"
  public_key = tls_private_key.kubadm_key.public_key_openssh

  tags = {
    Name = "Sept2026-kubadm-key"
  }
}

# Save private key locally
resource "local_file" "kubadm_key" {
  content         = tls_private_key.kubadm_key.private_key_pem
  filename        = "sept2026-key.pem"
  file_permission = "0400"
}

resource "aws_iam_role" "terraform_state_role" {
  name = "terraform-state-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::275755767148:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_state_access" {
  role       = aws_iam_role.terraform_state_role.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

# Creating Jenkins ALB
resource "aws_lb" "jenkins_lb" {
  name               = "${local.name}-jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_alb_sg.id]

  subnets = [
    aws_subnet.sept2026_public_subnet_1.id,
    aws_subnet.sept2026_public_subnet_2.id,
    aws_subnet.sept2026_public_subnet_3.id
  ]

  tags = {
    Name = "${local.name}-jenkins-lb"
  }
}

# Create Route53 record for Jenkins
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.sept2026_acp_zone.zone_id
  name    = "jenkins.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.jenkins_lb.dns_name
    zone_id                = aws_lb.jenkins_lb.zone_id
    evaluate_target_health = true
  }
}

# Create ACM certificate with DNS validation
resource "aws_acm_certificate" "sept2026_acm_cert" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name}-acm_cert"
  }
}

data "aws_route53_zone" "sept2026_acp_zone" {
  name         = var.domain
  private_zone = false
}

# Fetch DNS validation records for ACM certificate
resource "aws_route53_record" "acm_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.sept2026_acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.sept2026_acp_zone.zone_id
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  depends_on      = [aws_acm_certificate.sept2026_acm_cert]
}

# Validate ACM certificate after DNS record creation
resource "aws_acm_certificate_validation" "sept2026_cert_validation" {
  certificate_arn         = aws_acm_certificate.sept2026_acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_record : record.fqdn]
  depends_on              = [aws_acm_certificate.sept2026_acm_cert]
}

# Create IAM role for Jenkins server to assume SSM role
resource "aws_iam_role" "ssm_jenkins_role" {
  name = "${local.name}-ssm-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to Jenkins IAM role
resource "aws_iam_role_policy_attachment" "jenkins_ssm_policy" {
  role       = aws_iam_role.ssm_jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AdministratorAccess policy to Jenkins IAM role
resource "aws_iam_role_policy_attachment" "jenkins_admin_policy" {
  role       = aws_iam_role.ssm_jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create instance profile for Jenkins server
resource "aws_iam_instance_profile" "ssm_jenkins_profile" {
  name = "${local.name}-ssm-jenkins-profile"
  role = aws_iam_role.ssm_jenkins_role.name
}
# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create Jenkins EC2 server
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.sept2026_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  key_name = aws_key_pair.kubadm_key.key_name

  iam_instance_profile = aws_iam_instance_profile.ssm_jenkins_profile.name

  user_data = file("${path.module}/userdata.sh")

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name}-jenkins-server"
  }

  # This pipeline runs ON this instance. Changing user_data makes AWS stop the
  # instance, and a new AMI replaces it - either kills Jenkins mid-apply.
  lifecycle {
    ignore_changes = [ami, user_data, associate_public_ip_address]
  }
}

# Target group for Jenkins
resource "aws_lb_target_group" "jenkins_tg" {
  name     = "${local.name}-jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.sept2026_vpc.id

  health_check {
    enabled             = true
    path                = "/login"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${local.name}-jenkins-tg"
  }
}

# Attach Jenkins EC2 instance to target group
resource "aws_lb_target_group_attachment" "jenkins_attachment" {
  target_group_arn = aws_lb_target_group.jenkins_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 8080
}

# HTTP listener - redirect traffic to HTTPS
resource "aws_lb_listener" "jenkins_http" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener for Jenkins
resource "aws_lb_listener" "jenkins_https" {
  load_balancer_arn = aws_lb.jenkins_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.sept2026_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}