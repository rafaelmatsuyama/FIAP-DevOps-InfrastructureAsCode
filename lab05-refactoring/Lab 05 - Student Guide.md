# Lab 05 - Refactoring and Modularization (Creating Terraform Modules)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, HCL Modules  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Learn how to decouple monolithic infrastructure definitions into maintainable, reusable Terraform modules:
1. Master modular architecture design principles (*root* and *child modules*).
2. Establish formal input variable contracts (`variables.tf`) and output schemas (`outputs.tf`).
3. Instantiate local parameterized modules inside root manifests (`main.tf`).
4. Re-export child module outputs for root consumers and external pipelines.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab05-refactoring
  ```

---

## 🏗️ Architectural Module Layout

```text
lab05-refactoring/
├── main.tf                 # Root module (orchestrates module calls)
└── modules/
    └── ec2/                # Reusable child module
        ├── main.tf         # Parameterized aws_instance resource
        ├── variables.tf    # Input variables contract
        └── outputs.tf      # Output schema specification
```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Child Module Contracts
Inspect files inside `modules/ec2/`:
- **`variables.tf`:** Declares required inputs (`ami`, `instance_type`, `security_groups`, and `name`) with descriptions and defaults.
- **`main.tf`:** Declares `aws_instance.example` mapped to input parameters (`ami = var.ami`).
- **`outputs.tf`:** Exposes `aws_instance.example.public_ip` outside the child module scope.

### Step 2: Inspect Root Module Invocation
Open root `main.tf` and review the module block:
```hcl
module "ec2_instance" {
  source = "./modules/ec2"

  ami             = "ami-0de716d6197524dd9"
  instance_type   = "t2.micro"
  security_groups = ["allow_ssh_http"]
  name            = "Terraform Module Example"
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
```

### Step 3: Initialize and Register Modules
Whenever a new module is introduced, run init to record module tree mapping:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

1. **Validate Re-exported Output:**
   Query the root output value:
   ```bash
   terraform output instance_public_ip
   ```
   *Acceptance Criteria:* Command prints the valid public IPv4 address dynamically provisioned by AWS.
2. **Verify via AWS CLI:**
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Terraform Module Example'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table
   ```
   *Acceptance Criteria:* An EC2 instance in `running` status is returned.

---

## 🧹 Cleanup

Teardown resources provisioned by the module:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Multiple Module Instantiation:** Instantiate a second instance (`module "ec2_backup"`) in `main.tf` with a different name and instance sizing. Notice how Terraform manages identical resources DRYly.
2. **Input Validation Block:** Add a `validation` block in `variables.tf` enforcing that `instance_type` must belong to `["t2.micro", "t3.micro"]`.
