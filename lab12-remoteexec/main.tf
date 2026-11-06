terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Substitua pela sua região
}

resource "aws_security_group" "allow_ssh_nginx" {
  name        = "allow_ssh_nginx"
  description = "Permitir SSH (porta 22) e HTTP (porta 80)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "example" {
  ami             = "ami-0de716d6197524dd9" # Substitua pela AMI da sua região
  instance_type   = "t2.micro"
  key_name        = "vockey" # No AWS Academy, a chave padrão é "vockey"
  security_groups = [aws_security_group.allow_ssh_nginx.name]

  tags = {
    Name = "Remote Exec Example"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"                          # Para Amazon Linux 2 / AMI oficial
    private_key = file("${path.module}/labsuser.pem") # Caminho relativo da chave na pasta do Lab
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx"
    ]
  }
}

output "instance_public_ip" {
  description = "IP público da instância EC2 provisionada"
  value       = aws_instance.example.public_ip
}
