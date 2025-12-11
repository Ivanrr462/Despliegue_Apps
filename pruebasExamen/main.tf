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

// Grupos de seguridad
resource "aws_security_group" "Bastion" {
  description = "Allow Bastion traffic"
}

resource "aws_security_group" "FrontEnd" {
  description = "Allow FrontEnd traffic"
}

resource "aws_security_group" "BackEnd" {
  description = "Allow BackEnd traffic"
}

resource "aws_security_group" "all" {
  description = "Allow All traffic"
}

// Reglas de seguridad
// Salida
resource "aws_vpc_security_group_egress_rule" "all" {
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.all.id
}

// SSH
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.Bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_FrontEnd" {
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  referenced_security_group_id = aws_security_group.Bastion.id
  security_group_id = aws_security_group.FrontEnd.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_BackEnd" {
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  referenced_security_group_id = aws_security_group.Bastion.id
  security_group_id = aws_security_group.BackEnd.id
}

// HTTP
resource "aws_vpc_security_group_ingress_rule" "http_FrontEnd" {
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.FrontEnd.id
}

resource "aws_vpc_security_group_ingress_rule" "http_BackEnd" {
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  referenced_security_group_id = aws_security_group.FrontEnd.id
  security_group_id = aws_security_group.BackEnd.id
}

// Instancias
// Creacion de la instancia Bastion
resource "aws_instance" "Bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.Bastion.id, aws_security_group.all.id ]
  tags = {
    Name = "Bastion"
  }
}

// Creacion de la instancia de FrontEnd
resource "aws_instance" "FrontEnd" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.FrontEnd.id, aws_security_group.all.id ]
  tags = {
    Name = "FrontEnd"
  }
  user_data = templatefile("frontend.sh", {
    backend_ip = aws_instance.BackEnd.private_ip
  })
  user_data_replace_on_change = true
  depends_on = [ aws_instance.BackEnd ]
}

// Creacion de la instancia de BackEnd
resource "aws_instance" "BackEnd" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [ aws_security_group.BackEnd.id, aws_security_group.all.id ]
  tags = {
    Name = "BackEnd"
  }
  user_data = file("backend.sh")
  user_data_replace_on_change = true
}

// Elastic IP y asociación a la instancia webserver
resource "aws_eip" "ipelastica" {
  instance = aws_instance.FrontEnd.id
  domain = "vpc"
  tags = {
    Name = "ip elastica"
  }
}

// Ruta 53 
// Si le pongo vpc es privada, sino es pública
resource "aws_route53_zone" "default" {
  name = var.domain
  /*vpc {
    vpc_id = data.aws_vpc.default_vpc.id
    vpc_region = var.region
  }*/
}

resource "aws_route53_record" "frontend_record" {
  type = "A"
  name = "fe.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_eip.ipelastica.public_ip ] // Referencia a elastic IP
}

// Subdominio con CNAME
resource "aws_route53_record" "frontend_alias" {
  type = "CNAME"
  name = "www.fe.${var.domain}"
  zone_id = aws_route53_zone.default.zone_id
  ttl = 3600
  records = [ aws_route53_record.frontend_record.name ] // Referencia al name del frontend_record
}

