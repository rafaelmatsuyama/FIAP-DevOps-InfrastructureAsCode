# Lab 07 - Iterative Structures with Count (Multiple Instances)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, Meta-argument `count`  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Learn how to scale infrastructure provisioning from a single declarative definition using the `count` meta-argument:
1. Understand the mechanics and lifecycle of index-based resources managed via `count`.
2. Utilize the built-in variable `count.index` to dynamically customize naming and tagging conventions.
3. Understand array-based state tracking (`aws_instance.count_example[0]`).
4. Evaluate operational constraints and index shift vulnerabilities during downscaling.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab07-count
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Analyze Manifest `main.tf`
Open `main.tf` and review the index-based declaration:
```hcl
resource "aws_instance" "count_example" {
  count         = 3
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = "Instance ${count.index + 1}"
  }
}
```
- **`count = 3`:** Directs Terraform to iterate over this resource definition 3 times.
- **`${count.index + 1}`:** Accesses the zero-based index to generate deterministic names: `Instance 1`, `Instance 2`, and `Instance 3`.

### Step 2: Initialize and Preview Plan
```bash
terraform init
terraform plan
```
*Notice that Terraform tracks each individual resource using bracket notation: `aws_instance.count_example[0]`, `[1]`, and `[2]`.*

### Step 3: Batch Provisioning
```bash
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

1. **Verify via AWS CLI:**
   List all instances matching the naming pattern:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Instance *'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Acceptance Criteria:* 3 running EC2 instances named `Instance 1`, `Instance 2`, and `Instance 3` are displayed.
2. **Inspect Indexed State:**
   ```bash
   terraform state list
   ```
   *Acceptance Criteria:* Lists 3 distinct resources with array indexes.

---

## 🧹 Cleanup

Teardown instances to avoid cloud budget exhaustion:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Conditional Provisioning:** Declare a boolean input `variable "enable_monitoring" { default = true }`. Use ternary logic `count = var.enable_monitoring ? 1 : 0` to control resource creation conditionally.
2. **Export IP Array:** Add an output block `output "instance_ips"` returning all allocated public IPs using the splat expression: `value = aws_instance.count_example[*].public_ip`.
