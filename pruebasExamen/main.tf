terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

// Grupos de seguridad
resource "aws_security_group" "ssh" {
    name = "ssh-demo-bastion"
    description = "Allow SSH traffic"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  to_port = 22
  ip_protocol = "TCP"
}

resource "aws_security_group" "http" {
    name = "http-demo-bastion"
    description = "Allow HTTP traffic"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.http.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "TCP"
}

resource "aws_security_group" "all" {
    name = "all-demo-bastion"
    description = "Allow All traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.all.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

// Instancias
resource "aws_instance" "Bastion1" {
  ami = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.small"
  key_name = "demo"
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.http.id, aws_security_group.ssh.id]
  tags = {
    Name = "Bastion"
  }
  user_data = file("bastion_apache.sh")
  user_data_replace_on_change = true
}

// Elastic IP (VPC) y asociación a la instancia bastion
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.Bastion1.id
  tags = {
    Name = "bastion-eip"
  }
}