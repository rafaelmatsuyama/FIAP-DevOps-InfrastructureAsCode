# Lab 06 - Dynamic Queries (Using Data Sources in Terraform)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, Data Sources  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Learn how to decouple hardcoded infrastructure variables through dynamic API queries using Data Sources:
1. Understand architectural differences between managed resources (`resource`) and read-only data queries (`data`).
2. Configure search filters to discover cloud operating system images dynamically (`aws_ami`).
3. Resolve the latest official Canonical Ubuntu 20.04/22.04 AMI deterministically.
4. Provision EC2 instances dynamically bound to real-time query results.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab06-datasource
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Analyze `data "aws_ami"` Query in `main.tf`
Open `main.tf` and inspect the data query block:
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical Official Owner ID
}
```
*Terraform queries the AWS EC2 catalog during plan evaluation and resolves the most recent image ID.*

### Step 2: Resource Cross-Referencing
Notice how the dynamic AMI ID is referenced in `aws_instance`:
```hcl
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "Data Sources Example"
  }
}
```

### Step 3: Lifecycle Execution
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Notice that `terraform plan` displays the literal AMI ID (e.g. `ami-0...`) resolved prior to execution.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify via AWS CLI:**
   Query the image attached to the newly created instance:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Data Sources Example'" --query "Reservations[*].Instances[*].[InstanceId,ImageId,State.Name]" --output table
   ```
   *Acceptance Criteria:* The returned `ImageId` must match the dynamic AMI resolved by the Data Source.
2. **Inspect Data Source Attributes:**
   ```bash
   terraform state show data.aws_ami.ubuntu
   ```
   *Acceptance Criteria:* Displays image architecture (`x86_64`), root device type (`ebs`), and creation date.

---

## 🧹 Cleanup

Teardown resources to release cloud budget:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Query Default VPC:** Add a `data "aws_vpc" "default" { default = true }` block and export its `id` and `cidr_block` via an `output`.
2. **Filter for Amazon Linux 2023:** Update the `data "aws_ami"` filters to dynamically discover the latest Amazon Linux 2023 AMI owned by `137112412989` (Amazon).
