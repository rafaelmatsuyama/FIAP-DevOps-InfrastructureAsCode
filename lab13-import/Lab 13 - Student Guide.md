# Lab 13 - Importing Existing Infrastructure (Terraform Import)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, `terraform import`  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Learn how to bring unmanaged legacy (*brownfield*) cloud resources under Terraform version control without downtime:
1. Understand challenges of adopting legacy infrastructure into declarative IaC pipelines.
2. Define skeleton resource definitions in `main.tf` to receive imported cloud state.
3. Execute `terraform import` to bind physical AWS cloud IDs (`i-0...`) to logical HCL resource addresses.
4. Audit and eliminate configuration drift (*drift reconciliation*) using `terraform state show` and `terraform plan`.
5. Apply updates and decommission imported resources cleanly via automated workflows.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- An active EC2 instance running in your account (or launched via console/CLI with tag `Legacy Instance`).
- Terminal navigated to the lab directory:
  ```bash
  cd lab13-import
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Discover Physical Cloud Resource ID
Capture the active instance ID from AWS:
```bash
INSTANCE_ID=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].InstanceId" --output text)
echo "Target Instance ID: $INSTANCE_ID"
```

### Step 2: Skeleton Block in `main.tf`
Open `main.tf` and verify that the target resource block exists:
```hcl
resource "aws_instance" "example" {
  # Exact attributes will be reconciled post-import
  ami           = "ami-placeholder"
  instance_type = "t2.micro"

  tags = {
    Name = "Brownfield Resource"
  }
}
```

### Step 3: Run State Import
```bash
terraform init
terraform import aws_instance.example $INSTANCE_ID
```
*Terraform queries the AWS API, writes the JSON state into `terraform.tfstate`, and outputs `Import successful!`.*

### Step 4: Reconcile Configuration Drift (Zero-Drift Convergence)
Inspect the newly recorded state attributes:
```bash
terraform state show aws_instance.example
```
Compare with plan:
```bash
terraform plan
```
*Adjust resource attributes (`ami`, `instance_type`, `tags`) in `main.tf` until the plan outputs:*
`No changes. Your infrastructure matches the configuration.`

---

## 🧪 Validation & Acceptance Criteria

1. **Verify Active Code Governance:**
   Update the `Name` tag in `main.tf` to `"Imported Managed Instance"` and apply:
   ```bash
   terraform apply -auto-approve
   ```
2. **Verify via AWS CLI:**
   ```bash
   aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value|[0]" --output text
   ```
   *Acceptance Criteria:* The tag returned matches `Imported Managed Instance`.

---

## 🧹 Cleanup

Decommission the resource managed under Terraform:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Declarative Import Block (Terraform 1.5+):** Explore modern HCL import blocks:
   ```hcl
   import {
     to = aws_instance.example
     id = "i-0123456789abcdef0"
   }
   ```
   Execute `terraform plan -generate-config-out=generated.tf` and evaluate the automatically scaffolded manifest.
2. **Import Security Group:** Import a pre-existing `aws_security_group` along with its ingress rules into state.
