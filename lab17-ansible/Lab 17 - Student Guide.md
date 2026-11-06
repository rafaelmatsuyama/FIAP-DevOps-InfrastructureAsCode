# Lab 17 - Multi-Host Automation with Ansible & Jinja2 Templates

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, Ansible Core 2.16+, EC2, Jinja2 Templates, Nginx  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Implement the industry-standard hybrid automation model (IaC + Configuration Management):
1. Establish separation of concerns: Terraform provisions cloud hardware while Ansible configures operating systems.
2. Structure static multi-host inventories and validate parallel connectivity using the `ping` module.
3. Harvest machine telemetry (`gather_facts`) and render dynamic configurations using Jinja2 templates (`.j2`).
4. Validate and certify the core principle of **Idempotency** (`changed=0` on subsequent runs).

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Private key `labsuser.pem` available for SSH authentication.
- Terminal navigated to the lab directory:
  ```bash
  cd lab17-ansible
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Provision Cloud Infrastructure with Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```
*Note the allocated public IPs printed under the `public_ips` output.*

### Step 2: Configure Ansible Inventory
1. Move to the Ansible configuration directory:
   ```bash
   cd ../ansible
   ```
2. Enforce secure permissions on the private key:
   ```bash
   chmod 400 labsuser.pem
   ```
3. Update `inventory.ini` with the provisioned IP addresses:
   ```ini
   [webservers]
   servidor-01 ansible_host=SERVER_01_IP
   servidor-02 ansible_host=SERVER_02_IP

   [webservers:vars]
   ansible_user=ubuntu
   ansible_ssh_private_key_file=./labsuser.pem
   ansible_ssh_common_args='-o StrictHostKeyChecking=no'
   ```

### Step 3: Parallel Connectivity Ping
Verify SSH connectivity across all inventory hosts:
```bash
ansible webservers -i inventory.ini -m ping
```
*Expected: `"ping": "pong"` in green for all nodes.*

### Step 4: Execute Configuration Playbook
Apply package installation and Jinja2 rendering:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Step 5: Test Idempotency
Immediately re-run the playbook without modifying files:
```bash
ansible-playbook -i inventory.ini playbook.yml
```
*Review the execution recap: `ok=5 changed=0 unreachable=0 failed=0`. Ansible recognizes that the target state is already achieved and performs zero unnecessary changes.*

---

## 🧪 Validation & Acceptance Criteria

1. **HTTP Probe Verification:**
   ```bash
   curl -s http://SERVER_01_IP | grep "Hostname:"
   curl -s http://SERVER_02_IP | grep "Hostname:"
   ```
   *Acceptance Criteria:* Both servers return custom HTML displaying their individual hostnames and private IPs rendered dynamically by Jinja2.

---

## 🧹 Cleanup

Teardown instances and associated security groups:
```bash
cd ../terraform
terraform destroy -auto-approve
cd ../..
```

---

## 💡 Supplementary Challenges

1. **Service Restart Handlers:** Add a `handler` in Ansible to restart Nginx only when `index.html.j2` changes.
2. **Custom Group Variables:** Define `site_title = "FIAP Enterprise Cluster"` in `[webservers:vars]` and inject it into the Jinja2 template.
