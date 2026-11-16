terraform {
  backend "s3" {
    bucket         = "terraform-state-fiap-your-initials" # Match the S3 bucket name created in main.tf
    key            = "terraform.tfstate"                  # State file key path inside the bucket
    region         = "us-east-1"                          # Replace with your target AWS region
    dynamodb_table = "terraform-locks"                    # Match the DynamoDB lock table created in main.tf
    encrypt        = true                                 # Enable server-side encryption for remote state
  }
}