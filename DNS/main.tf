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

resource "aws_security_group" "webServer" {
    description = "Allow WebServer traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.webServer.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.webServer.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.webServer.id
}


resource "aws_instance" "webserver" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.webServer.id ]
  tags = {
    Name = "servidorWeb"
  }
  user_data = file("user_data.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.webServer.id ]
  tags = {
    Name = "Bastion"
  }
}

resource "aws_route53_zone" "default" {
  name = var.domain
  vpc {
    vpc_id = data.aws_vpc.default_vpc.id
    vpc_region = var.region
  }
}

resource "aws_route53_record" "webserver" {
  type = "A"
  name = var.domain
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.webserver.private_ip ]
}

resource "aws_route53_record" "webserver_alias" {
  type = "CNAME"
  name = "www.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_route53_record.webserver.name ]
}

resource "aws_route53_record" "bastion" {
  type = "A"
  name = "bastion.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.bastion.private_ip ]
}

