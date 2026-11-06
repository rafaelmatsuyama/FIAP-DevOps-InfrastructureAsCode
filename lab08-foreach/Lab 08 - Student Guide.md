# Lab 08 - Iterative Structures with For Each (Instance Mapping)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, Meta-argument `for_each`  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Master the `for_each` meta-argument for deterministic, key-based infrastructure collection management:
1. Understand architectural advantages of `for_each` over `count` in avoiding destructive recreation cascades.
2. Utilize the `toset()` type-casting function to transform lists into unique key sets.
3. Map dynamic attributes by referencing contextual iterators `each.key` and `each.value`.
4. Inspect nominal string keys recorded inside the Terraform state (`aws_instance.foreach_example["web1"]`).

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab08-foreach
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Configuration in `main.tf`
Open `main.tf` and analyze the declaration:
```hcl
variable "instance_names" {
  type    = list(string)
  default = ["web1", "web2", "web3"]
}

resource "aws_instance" "foreach_example" {
  for_each      = toset(var.instance_names)
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = each.value
  }
}
```
- **`toset()`:** Transforms the list of strings into an idempotent unique set.
- **`each.value`:** Binds the current string item as the `Name` tag for the provisioned EC2 instance.

### Step 2: Initialize and Preview Plan
```bash
terraform init
terraform plan
```
*Notice that Terraform tracks each individual resource using nominal string keys (`["web1"]`, `["web2"]`, `["web3"]`) rather than numerical array indexes.*

### Step 3: Apply Declarative Infrastructure
```bash
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

1. **Verify via AWS CLI:**
   List all provisioned instances:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='web1','web2','web3'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Acceptance Criteria:* 3 running EC2 instances with designated names are returned.
2. **Inspect Key-Based State:**
   ```bash
   terraform state list
   ```
   *Acceptance Criteria:* Resources are identified by string keys (`aws_instance.foreach_example["web1"]`).

---

## 🧹 Cleanup

Teardown instances to avoid cloud budget exhaustion:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Iterate over Complex Maps:** Refactor `var.instance_names` into a structured map:
   ```hcl
   variable "instances" {
     type = map(object({ type = string, env = string }))
     default = {
       "web" = { type = "t2.micro", env = "dev" }
       "api" = { type = "t3.micro", env = "prod" }
     }
   }
   ```
   Set `for_each = var.instances` and assign `instance_type = each.value.type`.
2. **Output Map:** Create an output returning a dictionary mapping each instance name to its public IP address.
