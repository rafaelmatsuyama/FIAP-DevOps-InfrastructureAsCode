# Terraform Provider Configuration for Docker
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Provider connects to local Docker socket (available in Codespaces)
provider "docker" {}

# Resource: Pull official Nginx image from Docker Hub
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Resource: Provision and run web container
resource "docker_container" "nginx_web" {
  image = docker_image.nginx.image_id
  name  = "fiap-web-server"

  ports {
    internal = 80
    external = 8080
  }
}

# Outputs: Expose container runtime ID and local endpoint URL
output "container_id" {
  description = "Docker runtime ID of the provisioned Nginx container"
  value       = docker_container.nginx_web.id
}

output "web_url" {
  description = "Local HTTP URL to access the containerized Nginx server"
  value       = "http://localhost:${docker_container.nginx_web.ports[0].external}"
}
