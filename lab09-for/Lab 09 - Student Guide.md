# Lab 09 - Advanced Expressions with For Loops (Data Transformations)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, HCL `for` Expressions  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Master functional `for` expressions in HCL for advanced data structure manipulation:
1. Understand list and map comprehension syntax (`[for k, v in col : ...]` and `{for item in list : k => v}`).
2. Transform configuration key-value mappings into structured object lists.
3. Consume transformed collections directly inside `for_each` meta-arguments to provision heterogeneous resource configurations.
4. Filter collections using conditional `if` clauses within expressions.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab09-for
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Analyze `locals` Transformations
Open `main.tf` and inspect the transformation pipeline:
```hcl
locals {
  instance_types = {
    web1 = "t2.micro"
    web2 = "t2.small"
    web3 = "t2.medium"
  }

  instance_list = [for name, type in local.instance_types : {
    name = name
    type = type
  }]
}
```
- **`instance_types`:** Source dictionary mapping hostname strings to EC2 instance types.
- **`instance_list`:** Iterates through key-value pairs to emit a standardized list of objects.

### Step 2: Map Projection for `for_each`
Observe how the list is projected into a uniquely keyed map for `for_each`:
```hcl
resource "aws_instance" "for_example" {
  for_each      = { for instance in local.instance_list : instance.name => instance }
  ami           = "ami-0de716d6197524dd9"
  instance_type = each.value.type

  tags = {
    Name = each.key
  }
}
```

### Step 3: Execution and Verification
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Review the execution plan: `web1` is assigned `t2.micro`, `web2` receives `t2.small`, and `web3` is allocated `t2.medium`.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify via AWS CLI:**
   List all instances with their allocated instance sizing:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='web1','web2','web3'" --query "Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Acceptance Criteria:* Each instance must display its respective `InstanceType`.
2. **Inspect Formatted Outputs:**
   ```bash
   terraform output
   ```

---

## 🧹 Cleanup

Teardown resources to conserve cloud budget:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Conditional Filtering:** Create an output returning only servers configured with type `"t2.micro"` using an `if` expression:
   ```hcl
   output "micro_instances" {
     value = [for k, v in local.instance_types : k if v == "t2.micro"]
   }
   ```
2. **Host-to-IP Dictionary:** Write a comprehension generating a dictionary `{ "web1" => "PUBLIC_IP_1", ... }` directly from `aws_instance.for_example`.
