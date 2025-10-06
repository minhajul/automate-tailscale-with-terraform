variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpc_tag_name" {
  description = "VPC tag name"
  type        = string
}

variable "aws_internet_gateway_tag_name" {
  description = "Internet gateway tag name"
  type        = string
}

variable "aws_nat_gateway_name" {
  description = "NAT gateway name"
  type        = string
}

variable "aws_security_group_name" {
  description = "Security group name"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}