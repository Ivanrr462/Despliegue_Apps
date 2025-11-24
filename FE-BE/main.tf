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

//Security Group SSH
resource "aws_security_group" "ssh" {
  description = "Allow SSH trafics"
  name        = "ssh-demo"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.ssh.id
  to_port           = 22
  from_port         = 22
  ip_protocol       = "TCP"
  cidr_ipv4         = "0.0.0.0/0"
}

// SECURITY GROUP FRONTEND 

resource "aws_security_group" "frontend" {
  name        = "frontend-sg"
  description = "Security Group for FrontEnd"
}

# SSH desde cualquier lado
resource "aws_vpc_security_group_ingress_rule" "frontend_ssh" {
  security_group_id = aws_security_group.frontend_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTP desde cualquier lado
resource "aws_vpc_security_group_ingress_rule" "frontend_http" {
  security_group_id = aws_security_group.frontend_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Egress libre
resource "aws_vpc_security_group_egress_rule" "frontend_egress" {
  security_group_id = aws_security_group.frontend_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


// SECURITY GROUP BACKEND 

resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Security Group for BackEnd"
}

# SSH desde cualquier lado
resource "aws_vpc_security_group_ingress_rule" "backend_ssh" {
  security_group_id = aws_security_group.backend_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTP SOLO desde FrontEnd
resource "aws_vpc_security_group_ingress_rule" "backend_http_from_frontend" {
  security_group_id            = aws_security_group.backend_sg.id
  referenced_security_group_id = aws_security_group.frontend_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# Egress libre
resource "aws_vpc_security_group_egress_rule" "backend_egress" {
  security_group_id = aws_security_group.backend_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "Frontend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  tags = {
    Name = "FrontEnd"
  }
  vpc_security_group_ids = [ aws_security_group.frontend.id ]
  user_data                   = file("frontend_data.sh")
  user_data_replace_on_change = true
}

resource "aws_instance" "Backend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  tags = {
    Name = "BackEnd"
  }
  vpc_security_group_ids = [ aws_security_group.backend.id ]
  user_data                   = file("backend_data.sh")
  user_data_replace_on_change = true
}

//////////////////Route53////////////////////
resource "aws_route53_zone" "default" {
  name = var.domain
  vpc {
    vpc_id = data.aws_vpc.default_vpc.id
  }
}

# Registro DNS para el FrontEnd
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.default.id
  name    = "frontend.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.Frontend.private_ip]
}

# Registro DNS para el BackEnd
resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.default.id
  name    = "backend.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.Backend.private_ip]
}