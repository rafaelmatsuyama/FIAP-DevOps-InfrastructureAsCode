# Lab 18 - Zero-Touch Orchestration (Terraform + Ansible Integrated)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, Ansible Core 2.16+, AWS EC2, Jinja2, Zero-Touch Pipeline  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Build an automated end-to-end Zero-Touch infrastructure provisioning and software configuration pipeline:
1. Orchestrate cloud resource creation via Terraform and dynamically emit formatted inventory artifacts (`local_file`).
2. Synchronize SSH daemon boot readiness using active polling probes with `remote-exec`.
3. Automate Ansible playbook invocation via `local-exec` coupled with lifecycle dependencies (`null_resource`).
4. Deliver fully configured, live production web applications in a single terminal execution (`terraform apply`).

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Private SSH key `labsuser.pem` located in the lab folder.
- Terminal navigated to the lab directory:
  ```bash
  cd lab18-zero-touch
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Enforce Private Key Permissions
In the Codespaces terminal:
```bash
chmod 400 labsuser.pem
```

### Step 2: Review Integration Mechanics in `main.tf`
Open `main.tf` and analyze the orchestration blocks:
1. **Dynamic Inventory Generation:**
   ```hcl
   resource "local_file" "ansible_inventory" {
     content = <<-EOT
     [webservers]
     servidor-zero-touch ansible_host=${aws_instance.web_server.public_ip}

     [webservers:vars]
     ansible_user=ubuntu
     ansible_ssh_private_key_file=${var.private_key_path}
     ansible_ssh_common_args='-o StrictHostKeyChecking=no'
     EOT

     filename = "${path.module}/inventory.ini"
   }
   ```
2. **Readiness Probe & Ansible Trigger:**
   ```hcl
   resource "null_resource" "trigger_ansible" {
     depends_on = [aws_instance.web_server, local_file.ansible_inventory]

     # SSH probe ensures OS boot is complete before calling playbook
     provisioner "remote-exec" {
       inline = ["echo 'SSH Ready!'"]
       connection {
         type        = "ssh"
         user        = "ubuntu"
         private_key = file(var.private_key_path)
         host        = aws_instance.web_server.public_ip
       }
     }

     # Automated Ansible invocation
     provisioner "local-exec" {
       command = "ansible-playbook -i inventory.ini playbook.yml"
     }
   }
   ```

### Step 3: Zero-Touch Execution
Launch the pipeline with a single command:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Observe the sequence: Terraform launches EC2 hardware, generates `inventory.ini`, polls SSH availability, triggers Ansible, configures Nginx, and prints the live URL.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify Generated Inventory:**
   ```bash
   cat inventory.ini
   ```
   *Acceptance Criteria:* File must contain the live public IP dynamically populated from the AWS provisioned instance.
2. **HTTP Application Probe:**
   Query the provisioned application endpoint:
   ```bash
   WEB_URL=$(terraform output -raw web_url)
   curl -s $WEB_URL | grep "Zero-Touch"
   ```
   *Acceptance Criteria:* Probe returns custom HTML with the Zero-Touch badge and server runtime metrics gathered by Ansible.

---

## 🧹 Cleanup

Teardown cloud compute and remove generated inventory files:
```bash
terraform destroy -auto-approve
rm -f inventory.ini
cd ..
```

---

## 💡 Supplementary Challenges

1. **Dynamic Inventory Plugin:** Replace static inventory generation with Ansible's official `amazon.aws.aws_ec2` plugin, dynamically discovering target hosts using EC2 tags (`tag:Project=ZeroTouch`).
2. **Failure Handling:** Add `on_failure = continue` to `local-exec` and evaluate how Terraform behaves if playbook tasks encounter errors on an intermediate node.
