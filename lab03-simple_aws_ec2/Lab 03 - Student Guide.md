# Lab 03 - Provisioning on AWS (Real Cloud vs. Local Emulation)

**Program:** Executive MBA in DevOps Engineering — Infrastructure as Code (IaC)  
**Platform / Environment:** GitHub Codespaces (AWS Academy / LocalStack)  
**Language / Stack:** Terraform 1.9+, AWS Provider (`hashicorp/aws ~> 5.0`), EC2, Security Groups, LocalStack  
**Estimated Duration:** 25 minutes  

---

## 🎯 Lab Objectives

Enable engineers to declaratively provision elastic compute resources on public cloud (AWS) while understanding provider portability between live cloud environments and local emulation.

**Enterprise Scenario (FinCorp Cloud Onboarding):**  
At *FinCorp*, developers frequently launch EC2 instances manually through the AWS Web Console (*ClickOps*) for quick validation, leaving administrative ports exposed or forgetting instances running overnight. Your mission is to replace manual clicks with an auditable Terraform manifest featuring an explicit Security Group, structured outputs, and clean automated teardown.

**Skills Acquired:**
1. Configure temporary credentials for live cloud (**AWS Academy**) or local emulation via **LocalStack**.
2. Declare virtual EC2 instances (`aws_instance`) and VPC firewall rules (`aws_security_group` attached via `vpc_security_group_ids`).
3. Expose resource identifiers and access IPs through `output` blocks.
4. Audit active instances via AWS CLI filtering by `running` state and destroy cloud assets cleanly.

---

## 📋 Prerequisites & Materials

- Active workspace in **GitHub Codespaces** (Terraform 1.9+ and AWS CLI v2 pre-installed in the DevContainer).
- Active **AWS Academy** credentials (Option A) **OR** active Docker daemon for **LocalStack** contingency (Option B).
- Provided lab manifest: [`main.tf`](./main.tf).
- Terminal navigated to the lab directory:
  ```bash
  cd lab03-simple_aws_ec2
  ```

> [!WARNING]
> **DevSecOps Best Practices (CIDR `0.0.0.0/0`):**  
> In this introductory lab, the `allow_ssh_http` Security Group opens SSH (port `22`) and HTTP (port `80`) to `0.0.0.0/0` for classroom simplicity in ephemeral AWS Academy sandboxes. **In production workloads**, never expose SSH port `22` to the entire internet: restrict `cidr_blocks` to your corporate VPN IP or adopt **AWS Systems Manager Session Manager (SSM)** with zero inbound SSH rules.

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Environment Setup (Choose one option)

#### 🟢 Option A: Live AWS (AWS Academy) — *Recommended*
1. On your AWS Academy lab dashboard (*Start Lab*), wait until the indicator turns green and copy credentials from **AWS Details** -> **AWS CLI**.
2. In Codespaces, open (or create) the standard AWS credentials file:
   ```bash
   mkdir -p ~/.aws && code ~/.aws/credentials
   ```
3. Paste the credentials using the exact structure provided by AWS Academy:
   ```ini
   [default]
   aws_access_key_id = YOUR_ACCESS_KEY_ID
   aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
   aws_session_token = YOUR_SESSION_TOKEN
   ```
4. Save the file (`Ctrl + S`) and verify active identity:
   ```bash
   aws sts get-caller-identity
   ```

#### 🟡 Option B: Emulated AWS (LocalStack — Contingency)
If working offline or without active AWS Academy access:
1. Launch the LocalStack container in background via Docker:
   ```bash
   docker run -d --name localstack -p 4566:4566 localstack/localstack
   ```
2. Verify that LocalStack is running with `docker ps`.

> [!NOTE]
> **LocalStack Community Scope vs. Live AWS:**  
> LocalStack's free (*Community*) edition emulates the EC2 control-plane API so you can practice the Terraform workflow (`init`, `plan`, `apply`, `destroy`) at zero cost, but the simulated VM does not boot a real guest OS or accept real SSH/HTTP network connections over its mocked IP.

---

### Step 2: Review and Adjust Provider in [`main.tf`](./main.tf)

Open [`main.tf`](./main.tf) and inspect its resource declarations:
- **If using Option A (AWS Academy):** Keep `OPTION A` active (lines 10–13) and `OPTION B` commented out.
- **If using Option B (LocalStack):** Comment out `provider "aws"` under `OPTION A` and uncomment the `OPTION B` block (lines 16–27) pointing to `http://localhost:4566`:
  ```hcl
  provider "aws" {
    region                      = "us-east-1"
    access_key                  = "mock"
    secret_key                  = "mock"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    endpoints {
      ec2 = "http://localhost:4566"
    }
  }
  ```

Also notice that `aws_instance.example` uses `vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]`, the modern VPC standard (replacing legacy EC2-Classic name references).

---

### Step 3: Initialize, Plan, and Provision

Execute the workflow sequentially in your terminal:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**Expected Output (Illustrative example in `us-east-1`):**
```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0a1b2c3d4e5f67890"
instance_public_ip = "54.123.45.67"
```
*(Under LocalStack, `instance_public_ip` may be empty or mocked depending on the LocalStack image version.)*

---

## 🧪 Validation & Acceptance Criteria

Validate the provisioned infrastructure via both the cloud control-plane API and Terraform state:

1. **Verify via AWS CLI (Live AWS — active instances only):**
   ```bash
   aws ec2 describe-instances \
     --filters "Name=instance-state-name,Values=running" \
     --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress,Name:Tags[?Key=='Name'].Value|[0]}" \
     --output table
   ```
   *Acceptance Criteria:* An instance tagged `Terraform Example` is displayed with `State = running` and an allocated `PublicIP`.

2. **Verify via AWS CLI (LocalStack):**
   ```bash
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
     --filters "Name=instance-state-name,Values=running" \
     --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" \
     --output table
   ```

3. **Audit Outputs and Tracked State:**
   ```bash
   terraform output
   terraform state list
   ```
   *Acceptance Criteria:* `terraform state list` returns exactly `aws_security_group.allow_ssh_http` and `aws_instance.example`.

---

## 🧹 Cleanup (Mandatory)

Destroy all provisioned cloud resources to prevent unnecessary AWS Academy credit consumption:
```bash
terraform destroy -auto-approve
cd ..
```
*If using LocalStack, stop and remove the container afterwards:*
```bash
docker stop localstack && docker rm localstack
```

---

## 💡 Supplementary Challenges

1. **Allocate Elastic IP (EIP):** Add an `aws_eip` resource linked to `aws_instance.example` and expose the static IP via `output "elastic_ip"`. (Remember to run `terraform destroy` afterwards, as idle unattached EIPs incur AWS charges!)
2. **Instance Resize Impact Analysis (`t2.micro` to `t3.micro`):** Change `instance_type` to `"t3.micro"` in `main.tf` and run **only** `terraform plan`. Inspect whether Terraform plans an *in-place* modification (`~`) or destructive replacement (`-/+`).
