terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# OPTION A: DEPLOY ON REAL AWS (AWS ACADEMY)
provider "aws" {
  region = "us-east-1"
}

# OPTION B: DEPLOY ON LOCALSTACK (CONTINGENCY)
# provider "aws" {
#   region                      = "us-east-1"
#   access_key                  = "mock"
#   secret_key                  = "mock"
#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#   endpoints {
#     ec2 = "http://localhost:4566"
#   }
# }

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"
  # vpc_id      = "vpc-xxxxxxxxxxxxxxxxx" # Optional: replace with your custom VPC ID

  # Lab simplicity: restrict SSH CIDR to your IP/VPN or use AWS SSM in production
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
  ami                    = "ami-0de716d6197524dd9" # Replace with the target region AMI if running outside us-east-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "Terraform Example"
  }
}

output "instance_id" {
  description = "Provisioned EC2 instance identifier"
  value       = aws_instance.example.id
}

output "instance_public_ip" {
  description = "Public IPv4 address allocated to the EC2 instance"
  value       = aws_instance.example.public_ip
}