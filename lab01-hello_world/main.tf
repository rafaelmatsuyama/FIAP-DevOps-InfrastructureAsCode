# Provider definitions (Local & Random - zero cloud cost)
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

# Resource: Random ID generator simulating a dynamic unique suffix
resource "random_id" "unique_suffix" {
  byte_length = 4
}

# Resource: Local text file created on disk
resource "local_file" "hello_fiap" {
  content  = "Olá, Engenheiro DevOps FIAP! Identificador exclusivo de infraestrutura: ${random_id.unique_suffix.hex}\n"
  filename = "${path.module}/hello_world.txt"
}
