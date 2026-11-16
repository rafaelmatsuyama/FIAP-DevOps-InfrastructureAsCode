terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket to store Terraform remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-fiap-your-initials" # Replace with a globally unique bucket name

  # Prevent accidental deletion of the state bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform State Bucket"
  }
}

# Enable versioning to allow state recovery across revisions
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create a DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks" # DynamoDB lock table name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Prevent accidental deletion of the lock table
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform DynamoDB Table"
  }
}

output "state_bucket_name" {
  description = "Name of the S3 bucket provisioned for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB table provisioned for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}