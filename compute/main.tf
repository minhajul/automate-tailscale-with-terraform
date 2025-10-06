resource "aws_key_pair" "web_key" {
  key_name   = "web_key"
  public_key = file(var.ssh_public_key_path)
}

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

locals {
  user_data = var.enable_logging ? templatefile("${path.module}/user_data_logging.sh", {
    tailscale_auth_key = var.tailscale_auth_key
    s3_bucket_name     = var.log_bucket_name
    aws_region         = var.aws_region
    log_group_name     = "/aws/ec2/tailscale"
  }) : templatefile("${path.module}/user_data.sh", {
    tailscale_auth_key = var.tailscale_auth_key
  })
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.web_key.key_name
  iam_instance_profile   = var.iam_instance_profile

  user_data         = local.user_data
  source_dest_check = false

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "tailscale-exit-node"
  }
}

resource "aws_eip" "tailscale" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name = "tailscale-eip"
  }
}