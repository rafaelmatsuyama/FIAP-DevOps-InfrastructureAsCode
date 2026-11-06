# Lab 11 - Local Provisioners (Local Exec Provisioner)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, `local-exec` Provisioner  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Understand the mechanics and operational trade-offs of local lifecycle provisioners (`local-exec`) in Terraform:
1. Master post-provisioning execution hooks triggered after cloud resource creation.
2. Capture dynamic cloud resource metadata (IP addresses and resource IDs) and persist them locally via shell execution.
3. Evaluate when provisioners act as an architectural anti-pattern and understand legitimate use cases.
4. Audit generated inventory manifests on the controller machine.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Terminal navigated to the lab directory:
  ```bash
  cd lab11-localexec
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review `local-exec` Configuration in `main.tf`
Open `main.tf` and inspect the instance resource:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = "Local Exec Example"
  }

  provisioner "local-exec" {
    command = "echo 'Instance created: ${self.id} | IP: ${self.public_ip}' > instance_info.txt"
  }
}
```
- **`local-exec`:** Executes shell commands locally on the operator's machine upon successful resource provisioning.
- **`self`:** Special reference object providing direct access to the parent resource's computed attributes.

### Step 2: Lifecycle Execution
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Observe terminal logs: Terraform streams command execution output directly to stdout.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify Generated Local Inventory:**
   Inspect the local text file:
   ```bash
   cat instance_info.txt
   ```
   *Acceptance Criteria:* The file contains the instance ID and its allocated public IP.
2. **Audit Applied State:**
   ```bash
   terraform show
   ```

---

## 🧹 Cleanup

Teardown cloud infrastructure and remove generated local files:
```bash
terraform destroy -auto-approve
rm -f instance_info.txt
cd ..
```

---

## 💡 Supplementary Challenges

1. **Destroy-Time Provisioner:** Add a teardown hook that runs exclusively during `terraform destroy`:
   ```hcl
   provisioner "local-exec" {
     when    = destroy
     command = "echo 'Instance destroyed at: $(date)' >> audit.log"
   }
   ```
2. **Ansible Inventory Generation:** Configure the command to format the IP address into an Ansible INI inventory (`echo "${self.public_ip} ansible_user=ec2-user" > hosts.ini`).
