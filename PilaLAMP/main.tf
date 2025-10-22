terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "pilaLAMP" {
  name        = "pilaLAMP"
  description = "Permitir HTTP y SSH"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "pilaLAMP"
  }
}

resource "aws_instance" "ServidorWeb" {
  ami           = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.small"
  key_name      = "demo"
  tags = {
    Name = "ServidorWeb"
  }
  user_data = file("install_apache.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "DBServer" {
  ami           = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.small"
  key_name      = "demo"
  tags = {
    Name = "DBServer"
  }
  user_data = file("install_mysql.sh")
  user_data_replace_on_change = true
}
