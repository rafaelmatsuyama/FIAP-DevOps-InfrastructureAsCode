# Lab 14 - AWS Secrets Manager Integration (Secrets Management)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, Secrets Manager, EC2, `user_data`, `jsondecode()`  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Implement core DevSecOps principles for centralized secrets management and runtime dynamic injection:
1. Eliminate security anti-patterns of hardcoding passwords and API credentials inside Git-tracked HCL code.
2. Provision and manage structured JSON secrets using AWS Secrets Manager via console or AWS CLI.
3. Query active secret versions dynamically using the `aws_secretsmanager_secret_version` data source.
4. Parse structured JSON payloads using HCL's native `jsondecode()` built-in function.
5. Inject credentials securely into the EC2 instance bootstrap sequence via `user_data`.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab14-secrets
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Create Secret in AWS Secrets Manager
Using the AWS CLI inside your Codespaces terminal, create the structured secret payload:
```bash
aws secretsmanager create-secret \
  --name "database_credentials2" \
  --description "Database credentials for IaC lab" \
  --secret-string '{"username":"admin","password":"S3cureP@ssw0rd!2026"}' \
  --region us-east-1
```

### Step 2: Review Dynamic Secret Injection in `main.tf`
Open `main.tf` and analyze the data source and interpolation:
```hcl
data "aws_secretsmanager_secret_version" "example" {
  secret_id = "database_credentials2"
}

resource "aws_instance" "secrets_instance" {
  ami           = "ami-00ca32bbc84273381"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Username: ${jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["username"]}" > /tmp/secrets.txt
              echo "Password: ${jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["password"]}" >> /tmp/secrets.txt
              EOF

  tags = {
    Name = "Instance with Secrets"
  }
}
```

### Step 3: Lifecycle Execution
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Notice that Terraform masks sensitive values from stdout plan representations.*

---

## 🧪 Validation & Acceptance Criteria

1. **Query Instance ID via AWS CLI:**
   ```bash
   INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values='Instance with Secrets'" --query "Reservations[*].Instances[*].InstanceId" --output text)
   echo "Instance: $INSTANCE_ID"
   ```
2. **Audit Base64 Decoded `user_data`:**
   Inspect initialization data passed to the EC2 metadata service:
   ```bash
   aws ec2 describe-instance-attribute --instance-id $INSTANCE_ID --attribute userData --query "UserData.Value" --output text | base64 -d
   ```
   *Acceptance Criteria:* Decoded output contains injected username and password retrieved directly from Secrets Manager.

---

## 🧹 Cleanup

1. Teardown cloud compute:
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```
2. Force delete secret from Secrets Manager:
   ```bash
   aws secretsmanager delete-secret --secret-id "database_credentials2" --force-delete-without-recovery --region us-east-1
   ```

---

## 💡 Supplementary Challenges

1. **IAM Role & Instance Profile:** Instead of persisting credentials in `user_data`, attach an IAM Role granting Secrets Manager read permissions so the application retrieves credentials dynamically in memory.
2. **Automated Secret Rotation:** Explore configuring automated secret rotation using AWS Lambda triggers.
