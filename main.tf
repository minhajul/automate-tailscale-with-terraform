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

# Networking Module
module "networking" {
  source = "./networking"

  vpc_cidr                      = var.vpc_cidr
  vpc_tag_name                  = var.vpc_tag_name
  aws_internet_gateway_tag_name = var.aws_internet_gateway_tag_name
  aws_nat_gateway_name          = var.aws_nat_gateway_name
  aws_security_group_name       = var.aws_security_group_name
  availability_zones            = var.availability_zones
}

# Logging Module (Optional)
module "logging" {
  source = "./logging"
  count  = var.enable_logging ? 1 : 0

  log_bucket_name       = var.log_bucket_name
  log_retention_days    = var.log_retention_days
  enable_log_encryption = var.enable_log_encryption
  aws_region            = var.aws_region
}

# Compute Module
module "compute" {
  source = "./compute"

  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  ssh_public_key_path = var.ssh_public_key_path
  tailscale_auth_key  = var.tailscale_auth_key
  subnet_id           = module.networking.public_subnet_ids[0]
  security_group_id   = module.networking.security_group_id
  vpc_id = module.networking.vpc_id

  # Logging configuration
  enable_logging       = var.enable_logging
  log_bucket_name      = var.enable_logging ? var.log_bucket_name : ""
  aws_region           = var.aws_region
  iam_instance_profile = var.enable_logging ? module.logging[0].instance_profile_name : null
}
