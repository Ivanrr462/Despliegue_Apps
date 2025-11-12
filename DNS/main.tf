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

resource "aws_security_group" "ssh" {
    name = "ssh-demo-dns"
    description = "Allow SSH traffic"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
    cidr_ipv4 = "0.0.0.0/0"
    to_port = 22
    from_port = 22
    ip_protocol = "TCP"
    security_group_id = aws_security_group.ssh.id  
}

resource "aws_security_group" "all" {
    name = "all-demo-dns"
    description = "Allow All Egress traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    security_group_id = aws_security_group.all.id  
}

resource "aws_route53_zone" "dns" {
    name = "ivanrios.com"
}

resource "aws_route53_record" "dns" {
    zone_id = aws_route53_zone.dns.id
    name = "ivanrios.com"
    type = "A"
    ttl = 300
    records = 
}

resource "aws_instance" "webserver" {
  ami = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.small"
  key_name = "vockey"
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.ssh.id]
  tags = {
    Name = "servidorWeb"
  }
  user_data = file("user_data.sh")
  user_data_replace_on_change = true
}

