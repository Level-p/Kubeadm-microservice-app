# Create the Cluster VPC
resource "aws_vpc" "cluster_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-cluster-vpc"
  }
}

# Create Internet Gateway for the Cluster VPC
resource "aws_internet_gateway" "cluster_igw" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = "${var.name}-cluster-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.cluster_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.cluster_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.cluster_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-3"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.cluster_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${var.name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.cluster_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${var.name}-private-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.cluster_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "${var.name}-private-subnet-3"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_igw.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# Associate Public Subnet 1
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Public Subnet 2
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Public Subnet 3
resource "aws_route_table_association" "public_subnet_3_association" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway so the private nodes can reach the internet (apt, images, S3)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "cluster_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.cluster_igw]
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cluster_nat.id
  }

  tags = {
    Name = "${var.name}-private-rt"
  }
}

# Associate Private Subnet 1
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Private Subnet 2
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Private Subnet 3
resource "aws_route_table_association" "private_subnet_3_association" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_rt.id
}

#keypair
# Generate SSH private/public key pair
resource "tls_private_key" "kubadm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register public key with AWS
resource "aws_key_pair" "kubadm_key" {
  key_name   = "cluster-key"
  public_key = tls_private_key.kubadm_key.public_key_openssh

  tags = {
    Name = "Sept2026-cluster-key"
  }
}

# Save private key locally
resource "local_file" "kubadm_key" {
  content         = tls_private_key.kubadm_key.private_key_pem
  filename        = "${path.root}/cluster-key.pem"
  file_permission = "0400"
}