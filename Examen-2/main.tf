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

// Grupos de Seguridad
resource "aws_security_group" "all" {
  description = "Allow All Traffic"
  tags = {
    Name = "All"
  }
}

resource "aws_security_group" "Bastion" {
  description = "Allow Bastion Traffic"
  tags = {
    Name = "Bastion"
  }
}

resource "aws_security_group" "FrontEnd" {
  description = "Allow FrontEnd Traffic"
  tags = {
    Name = "FrontEnd"
  }
}

resource "aws_security_group" "Api" {
  description = "Allow Api Traffic"
  tags = {
    Name = "Api"
  }
}

resource "aws_security_group" "Login" {
  description = "Allow Login Traffic"
  tags = {
    Name = "Login"
  }
}

// Reglas de seguridad
// Salida
resource "aws_vpc_security_group_egress_rule" "all" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.all.id
}

// SSH
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.Bastion.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "TCP"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_FrontEnd" {
  security_group_id            = aws_security_group.FrontEnd.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "TCP"
  referenced_security_group_id = aws_security_group.Bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_Api" {
  security_group_id            = aws_security_group.Api.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "TCP"
  referenced_security_group_id = aws_security_group.Bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_Login" {
  security_group_id            = aws_security_group.Login.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "TCP"
  referenced_security_group_id = aws_security_group.Bastion.id
}

// HTTP
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.FrontEnd.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "TCP"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http_Api" {
  security_group_id = aws_security_group.Api.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "TCP"
  referenced_security_group_id = aws_security_group.FrontEnd.id
}

resource "aws_vpc_security_group_ingress_rule" "http_Login" {
  security_group_id = aws_security_group.Login.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "TCP"
  referenced_security_group_id = aws_security_group.Api.id
}

// Instancias
// Instancia del Bastion
resource "aws_instance" "Bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.Bastion_Type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.Bastion.id, aws_security_group.all.id ]
  tags = {
    Name = "Bastion"
  }
}

// Instancia del FrontEnd
resource "aws_instance" "FrontEnd" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.WebServer_Type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.all.id, aws_security_group.FrontEnd.id ]
  user_data = templatefile("frontend.tftpl", {
    API = aws_instance.Api.private_ip
  })
  user_data_replace_on_change = true
  depends_on = [ aws_instance.Api ]
  tags = {
    Name = "FrontEnd"
  }
}

// Instancia de la Api
resource "aws_instance" "Api" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.WebServer_Type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.all.id, aws_security_group.Api.id ]
  user_data = templatefile("api.tftpl", {
    LOGIN = aws_instance.Login.private_ip
  })
  user_data_replace_on_change = true
  depends_on = [ aws_instance.Login ]
  tags = {
    Name = "Api"
  }
}

// Instancia del Login
resource "aws_instance" "Login" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.WebServer_Type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.all.id, aws_security_group.Login.id ]
  user_data = file("login.sh")
  user_data_replace_on_change = true
  tags = {
    Name = "Login"
  }
}

// Route 53
resource "aws_route53_zone" "default" {
  name = var.domain
  vpc {
    vpc_id = data.aws_vpc.default_vpc.id
    vpc_region = var.region
  }
}

// Record del Bastion
resource "aws_route53_record" "bastion_record" {
  type = "A"
  name = "bastion.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.Bastion.private_ip ] 
}

// Record del FrontEnd
resource "aws_route53_record" "frontend_record" {
  type = "A"
  name = "frontend.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.FrontEnd.private_ip ] 
}

// Record de la Api
resource "aws_route53_record" "api_record" {
  type = "A"
  name = "api.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.Api.private_ip ] 
}

// Record del Login
resource "aws_route53_record" "login_record" {
  type = "A"
  name = "login.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_instance.Login.private_ip ] 
}