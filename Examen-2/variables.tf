variable "key_name" {
  type    = string
  default = "vockey"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "ivanrios.net"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "Bastion_Type" {
    type = string
    default = "t2.medium"
}

variable "WebServer_Type" {
    type = string
    default = "t2.large"
}

data "aws_vpc" "default_vpc" {
  default = true
  region  = var.region
}
