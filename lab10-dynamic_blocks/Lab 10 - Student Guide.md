# Lab 10 - Dynamic Blocks (Dynamic Nested Blocks in Terraform)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, EBS, `dynamic` blocks  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Learn how to eliminate boilerplate duplication of nested repetitive blocks in Terraform manifests using `dynamic`:
1. Understand the purpose and mechanics of dynamic blocks (`dynamic "<block>" { for_each = ... content { ... } }`).
2. Iterate through lists of storage specifications to attach multiple EBS volumes (`ebs_block_device`) to an EC2 instance.
3. Reference dynamic attributes using contextual iterators (`ebs_block_device.value.*`).
4. Validate attached block storage devices in the AWS console and via CLI.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab10-dynamic_blocks
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Dynamic Block Layout in `main.tf`
Open `main.tf` and analyze the resource declaration:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      delete_on_termination = true
    }
  }
}
```
- **`dynamic "ebs_block_device"`:** Instructs Terraform to generate multiple nested blocks inside `aws_instance`.
- **`for_each = var.ebs_volumes`:** Iterates through the list of volume objects defined in variables.
- **`content`:** Projects the body of each nested block using `ebs_block_device.value`.

### Step 2: Initialize and Preview Plan
```bash
terraform init
terraform plan
```
*Notice that the execution plan shows a single EC2 instance configured with multiple attached EBS block storage volumes.*

### Step 3: Apply Infrastructure
```bash
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

1. **Verify via AWS CLI:**
   Query block volumes attached to the provisioned instance:
   ```bash
   aws ec2 describe-volumes --filters "Name=attachment.device,Values='/dev/sdb','/dev/sdc'" --query "Volumes[*].[VolumeId,Size,VolumeType,State]" --output table
   ```
   *Acceptance Criteria:* Both volumes (`10GB` and `20GB`) must be listed in `in-use` state.
2. **Inspect Recorded State:**
   ```bash
   terraform show
   ```
   *Acceptance Criteria:* `ebs_block_device` blocks are recorded in state.

---

## 🧹 Cleanup

Teardown the instance and all attached storage volumes:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Dynamic Security Group Ingress:** Apply the `dynamic` pattern to generate firewall ingress rules (`dynamic "ingress"`) inside an `aws_security_group`, iterating over ports `[22, 80, 443]`.
2. **Enable Encryption:** Add `encrypted = true` inside the EBS `content` block to ensure all provisioned block devices are encrypted at rest.
