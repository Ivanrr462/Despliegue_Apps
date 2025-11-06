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
    name = "ssh-examen"
    description = "Allow SSH traffic in Web Server from Bastion only"
}

resource "aws_security_group" "bastionssh" {
    name = "ssh-examen-bastion"
    description = "Allow SSH traffic in Bastion"
}

resource "aws_vpc_security_group_ingress_rule" "sshbastion" {
  security_group_id = aws_security_group.bastionssh.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  to_port = 22
  ip_protocol = "TCP"
}

// Creacion de la regla de seguridad para que solo el grupo de seguridad bastionssh sea capaz de entrar.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ssh.id
  referenced_security_group_id = aws_security_group.bastionssh.id
  from_port = 22
  to_port = 22
  ip_protocol = "TCP"
}

resource "aws_security_group" "http" {
    name = "http-examen"
    description = "Allow HTTP traffic"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
    security_group_id = aws_security_group.http.id
    cidr_ipv4 = "0.0.0.0/0"
    to_port = 80
    from_port = 80
    ip_protocol = "TCP"
}

resource "aws_security_group" "http2" {
    name = "http2-examen"
    description = "Allow traffic in 8008"
}

resource "aws_vpc_security_group_ingress_rule" "http2" {
    security_group_id = aws_security_group.http2.id
    cidr_ipv4 = "0.0.0.0/0"
    to_port = 8008
    from_port = 8008
    ip_protocol = "TCP"
}

resource "aws_security_group" "all" {
    name = "all-examen"
    description = "Allow all traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
    security_group_id = aws_security_group.all.id
}

// Instancias
// Creacion de la instancia Bastion
resource "aws_instance" "Bastion" {
  ami = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.medium"
  key_name = "vockey"
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.bastionssh.id]
  tags = {
    Name = "Bastion"
  }
}

// Creacion de la instancia WebServer
resource "aws_instance" "webserver" {
  ami = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.large"
  key_name = "vockey"
  vpc_security_group_ids = [aws_security_group.all.id, aws_security_group.http.id, aws_security_group.http2.id, aws_security_group.ssh.id]
  tags = {
    Name = "webServer"
  }
  user_data = file("virtualhost.sh")
  user_data_replace_on_change = true
}

// Elastic IP y asociación a la instancia webserver
resource "aws_eip" "ipelastica" {
  instance = aws_instance.webserver.id
  tags = {
    Name = "ip elastica"
  }
}