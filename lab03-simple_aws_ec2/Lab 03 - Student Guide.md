# Lab 03 - Provisioning on AWS (Real Cloud vs. Local Emulation)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / LocalStack)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, Security Groups, LocalStack  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Learn how to provision elastic compute resources in public cloud and emulated local environments:
1. Configure credentials for live cloud (AWS Academy) or containerized LocalStack emulation.
2. Declare elastic compute instances (`aws_instance`) and firewall rules (`aws_security_group`).
3. Understand provider portability across development and production environments.
4. Audit running instances via AWS CLI and inspect cloud state attributes.

---

## 📋 Prerequisites & Materials

- Active workspace in **GitHub Codespaces** (Terraform and AWS CLI pre-installed).
- Active **AWS Academy** credentials OR active Docker daemon for LocalStack.
- Terminal navigated to the lab directory:
  ```bash
  cd lab03-simple_aws_ec2
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Environment Setup (Choose one option)

#### 🟢 Option A: Live AWS (AWS Academy)
If you have active temporary AWS Academy credentials:
1. From the AWS Academy dashboard, copy CLI credentials under **AWS Details** -> **AWS CLI**.
2. In Codespaces, open the credentials file:
   ```bash
   mkdir -p ~/.aws && code ~/.aws/credentials
   ```
3. Paste the credentials using the following structure:
   ```ini
   [default]
   aws_access_key_id = YOUR_ACCESS_KEY_ID
   aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
   aws_session_token = YOUR_SESSION_TOKEN
   ```
4. Save the file (`Ctrl + S`).

#### 🟡 Option B: Emulated AWS (LocalStack)
If working offline or without active AWS Academy access:
1. Launch LocalStack in background via Docker:
   ```bash
   docker run -d --name localstack -p 4566:4566 localstack/localstack
   ```
2. Verify that LocalStack is running: `docker ps`.

### Step 2: Configure Provider in `main.tf`
Open `main.tf` and adjust the provider block according to your chosen option:
- **For Option A (Live AWS):** Keep the default configuration:
  ```hcl
  provider "aws" {
    region = "us-east-1"
  }
  ```
- **For Option B (LocalStack):** Redirect endpoints to `http://localhost:4566`:
  ```hcl
  provider "aws" {
    region                      = "us-east-1"
    access_key                  = "mock"
    secret_key                  = "mock"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true

    endpoints {
      ec2 = "http://localhost:4566"
    }
  }
  ```

### Step 3: Initialize and Apply
Execute in your terminal:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

Validate the provisioned EC2 instance:

1. **Verify via AWS CLI (Live Cloud):**
   ```bash
   aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" --output table
   ```
   *Acceptance Criteria:* An instance tagged `Terraform Example` is displayed with state `running`.

2. **Verify via AWS CLI (LocalStack):**
   ```bash
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" --output table
   ```

3. **Inspect Recorded State:**
   ```bash
   terraform show
   ```
   *Acceptance Criteria:* `aws_instance.example` displays allocated `public_ip` and network interfaces.

---

## 🧹 Cleanup

Teardown resources to avoid cloud charges:
```bash
terraform destroy -auto-approve
cd ..
```
*If using LocalStack, stop and remove the container: `docker stop localstack && docker rm localstack`.*

---

## 💡 Supplementary Challenges

1. **Allocate Elastic IP (EIP):** Add an `aws_eip` resource associated with the EC2 instance and expose the IP address via an `output` block.
2. **Update Instance Sizing:** Change `instance_type` from `t2.micro` to `t3.micro`. Run `terraform plan` to evaluate whether this modification triggers in-place updates or instance replacement.
