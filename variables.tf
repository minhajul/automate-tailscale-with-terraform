variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_tag_name" {
  description = "VPC tag name"
  type        = string
  default     = "tailscale-vpc"
}

variable "aws_internet_gateway_tag_name" {
  description = "Internet gateway tag name"
  type        = string
  default     = "tailscale-igw"
}

variable "aws_nat_gateway_name" {
  description = "NAT gateway name"
  type        = string
  default     = "tailscale-nat"
}

variable "aws_security_group_name" {
  description = "Security group name"
  type        = string
  default     = "tailscale-sg"
}

variable "availability_zones" {
  description = "List of availability zones"
  type = list(string)
  default = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/web_key.pub"
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key"
  type        = string
  sensitive   = true
}

# Logging variables
variable "enable_logging" {
  description = "Enable Tailscale logging to S3"
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "enable_log_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = true
}