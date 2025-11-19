terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "Frontend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  tags = {
    Name = "FrontEnd"
  }
  user_data = file("frontend_data.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "Backend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  tags = {
    Name = "BackEnd"
  }
  user_data = file("backend_data.sh")
  user_data_replace_on_change = true
}