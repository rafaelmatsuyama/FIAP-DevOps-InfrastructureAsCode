# Lab 12 - Remote Provisioners (Remote Exec Provisioner)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, EC2, SSH, `remote-exec` Provisioner, Nginx  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Learn how to execute operating-system-level configuration scripts on newly launched EC2 instances via SSH using `remote-exec`:
1. Configure remote SSH transport blocks (`connection`) in Terraform with `.pem` private keys.
2. Understand strict dependencies between Security Groups (ports 22 and 80) and provisioner execution to prevent connection timeouts.
3. Execute unattended non-interactive bootstrapping commands (`yum update`, `nginx`).
4. Validate live web servers and analyze architectural trade-offs versus `user_data` or configuration management engines.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Private SSH key `labsuser.pem` (available from AWS Academy lab credentials).
- Terminal navigated to the lab directory:
  ```bash
  cd lab12-remoteexec
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Adjust SSH Private Key Permissions
In the Linux Codespaces container, set restrictive permissions (`400`):
```bash
chmod 400 labsuser.pem
```

### Step 2: Review Connection and Provisioner in `main.tf`
Open `main.tf` and analyze configuration:
```hcl
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/labsuser.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx"
    ]
  }
```
*Architectural Gotcha:* The EC2 instance must associate a Security Group permitting inbound traffic on port 22 (SSH). Omitting port 22 causes Terraform to wait indefinitely until timing out.

### Step 3: Execute Lifecycle Provisioning
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Terraform waits for SSH daemon readiness on the EC2 host, negotiates the encrypted tunnel, and streams Nginx installation logs in real time.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify Web Endpoint via Curl:**
   Extract public IP and execute an HTTP validation probe:
   ```bash
   INSTANCE_IP=$(terraform output -raw instance_public_ip)
   curl -I http://$INSTANCE_IP
   ```
   *Acceptance Criteria:* Probe returns `HTTP/1.1 200 OK` with header `Server: nginx`.
2. **Direct Process Audit:**
   ```bash
   ssh -i labsuser.pem ec2-user@$INSTANCE_IP "systemctl status nginx"
   ```
   *Acceptance Criteria:* Displays status `active (running)`.

---

## 🧹 Cleanup

Teardown infrastructure:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Refactor to `user_data`:** Eliminate the security footprint of `remote-exec` (open port 22) by refactoring package installation to native EC2 `user_data` using `cloud-init`.
2. **File Provisioner:** Add a `file` provisioner block to upload a custom static `index.html` file to `/usr/share/nginx/html/` prior to starting Nginx.
