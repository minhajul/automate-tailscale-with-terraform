terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# You need to create key pair first
resource "aws_key_pair" "web_key" {
  key_name   = "web_key"
  public_key = file("~/.ssh/web_key.pub")
}


# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_tag_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.aws_internet_gateway_tag_name
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = ["ap-southeast-1a", "ap-southeast-1b"][count.index] # Adjust zone
  tags = {
    Name = "terraform-public-${count.index}" # Adjust tags
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "terraform-public-rt" # Adjust route tables
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = var.aws_nat_gateway_name
  }
}

resource "aws_security_group" "app_sg" {
  name = var.aws_security_group_name
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# User data script to install and configure Tailscale
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh

    # Enable IP forwarding
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf

    # Start Tailscale and advertise as exit node
    tailscale up --authkey=${var.tailscale_auth_key} --advertise-exit-node --accept-routes

    echo "Tailscale exit node setup complete"
  EOF
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami = "ami-0b1e534a4ff9019e0" # Amazon Linux 2
  instance_type = "t2.micro" # Adjust instance type
  subnet_id = aws_subnet.public[0].id
  security_groups = [aws_security_group.app_sg.id]

  key_name  = var.key_pair_name
  public_key = file("~/.ssh/web_key.pub")

  user_data = local.user_data

  # Enable source/destination check disable for exit node
  source_dest_check = false

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "tailscale-exit-node"
  }
}

# Elastic IP
resource "aws_eip" "tailscale" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name = "tailscale-eip"
  }
}