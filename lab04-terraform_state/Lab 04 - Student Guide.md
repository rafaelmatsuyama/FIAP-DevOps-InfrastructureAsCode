# Lab 04 - Remote State Management (S3 Backend & State Locking)

**Program:** Executive MBA in DevOps Engineering — Infrastructure as Code (IaC)  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS S3, DynamoDB, Remote State Backend  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Enable engineers to architect secure, collaborative cloud infrastructure operations using Terraform remote state management on AWS.

**Enterprise Scenario (FinCorp Platform Engineering):**  
At *FinCorp*, two platform engineers ran `terraform apply` concurrently from their local laptops against stale local `terraform.tfstate` files, overwriting production configuration and corrupting shared infrastructure tracking. Your mission is to centralize state storage inside a versioned S3 bucket paired with distributed DynamoDB locking to guarantee atomic concurrency control and auditability.

**Skills Acquired:**
1. Provision a versioned S3 bucket (`aws_s3_bucket` + `aws_s3_bucket_versioning`) and a dedicated DynamoDB lock table (`LockID`).
2. Solve the bootstrap *Chicken-and-Egg* problem and migrate local state deterministically (`terraform init -migrate-state`).
3. Validate atomic state locking (*State Locking*) preventing race conditions across engineering teams.
4. Manage lifecycle safeguard rules (`prevent_destroy`) and perform safe teardown on versioned S3 buckets.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials` (verify beforehand using `aws sts get-caller-identity`).
- Provided lab files: [`main.tf`](./main.tf) and [`backend.tf`](./backend.tf).
- Integrated terminal located in the lab directory:
  ```bash
  cd lab04-terraform_state
  ```

> [!NOTE]
> **Why does `backend.tf` use literal values instead of `var.bucket_name`?**  
> Terraform evaluates the `terraform { backend "s3" { ... } }` block **before** loading input variables or resource definitions. Due to this HCL architectural constraint, `backend` blocks cannot contain interpolations; real-world CI pipelines supply dynamic targets via `-backend-config` or wrappers like Terragrunt.

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Globally Unique S3 Bucket Naming
AWS S3 bucket names must be globally unique across all accounts worldwide:
1. Open [`main.tf`](./main.tf) and replace `-your-initials` in `terraform-state-fiap-your-initials` with a unique suffix (e.g., `terraform-state-fiap-john-doe-2026`, lowercase letters, numbers, and hyphens only).
2. Open [`backend.tf`](./backend.tf) and enter the **exact same bucket name** in the `bucket` attribute.

### Step 2: Provision Storage Infrastructure (Local Phase — *Bootstrap*)
Because the S3 bucket and DynamoDB table do not exist yet, temporarily disable the remote backend block so Terraform creates them using local state:
```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply -auto-approve
```
**Expected Output:**
```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

dynamodb_lock_table = "terraform-locks"
state_bucket_name = "terraform-state-fiap-john-doe-2026"
```

### Step 3: Enable Remote Backend and Migrate State
Now that the underlying storage resources exist on AWS:
1. Re-enable the backend configuration file:
   ```bash
   mv backend.tf.disabled backend.tf
   ```
2. Trigger the state migration workflow:
   ```bash
   terraform init -migrate-state
   ```
3. When prompted with `Do you want to copy existing state to the new backend?`, type `yes` and press `Enter`.

**Expected Output (Excerpt):**
```text
Initializing the backend...
Acquiring state lock. This may take a few moments...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Releasing state lock. This may take a few moments...
```

> [!TIP]
> **Evolution Note (Terraform 1.10+):**  
> This lab demonstrates `dynamodb_table` (standard across Terraform `<= 1.9` and established enterprise stacks). Starting in Terraform `1.10+`, the `s3` backend also supports native S3 object locking via `use_lockfile = true`, removing the DynamoDB dependency in greenfield setups.

---

## 🧪 Validation & Acceptance Criteria

1. **Validate Distributed State Locking (DynamoDB):**
   ```bash
   terraform plan
   ```
   *Acceptance Criteria:* Terminal logs print `Acquiring state lock` before reading state and `Releasing state lock` upon completion, returning `No changes. Your infrastructure matches the configuration.`

2. **Audit Remote S3 Objects via AWS CLI:**
   ```bash
   aws s3 ls s3://YOUR-BUCKET-NAME/
   ```
   *Acceptance Criteria:* The `terraform.tfstate` object appears inside the remote bucket.

---

## 🧹 Cleanup (Mandatory Sequence)

Because `prevent_destroy = true` and S3 versioning are active, follow this exact order to avoid teardown errors:

1. **Disable Lifecycle Safeguards in [`main.tf`](./main.tf):**
   Change `prevent_destroy = false` in both `lifecycle` blocks (`aws_s3_bucket` and `aws_dynamodb_table`).
2. **Migrate State Back to Local Disk:**
   ```bash
   mv backend.tf backend.tf.disabled
   terraform init -migrate-state
   ```
   *Confirm with `yes` to move state back from S3 onto your local filesystem.*
3. **Empty Versioned S3 Objects (if required):**
   Because S3 versioning retains historical revisions of `terraform.tfstate`, if `terraform destroy` fails with `BucketNotEmpty`, empty all object versions/delete markers (via AWS Console -> **Empty bucket** or AWS CLI) before re-running `destroy`.
4. **Destroy Cloud Resources:**
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```

> [!WARNING]
> **AWS Academy Session Timer:**  
> Complete the teardown sequence before your AWS Academy lab session timer expires; otherwise leftover resources remain locked until the sandbox resets.

---

## 💡 Supplementary Challenges

1. **Simulate Concurrent Lock Collision:** Open two Codespaces terminal tabs. In Terminal 1, run `terraform apply` and **leave it waiting** at the `Enter a value:` confirmation prompt. In Terminal 2, run `terraform plan`. Inspect the `Error acquiring the state lock` exception displaying `Lock Info` (ID, caller, and timestamp). (Cancel Terminal 1 with `Ctrl + C` or `no` to release the lock.)
2. **AWS KMS Server-Side Encryption:** Add an `aws_kms_key` resource and configure `aws_s3_bucket_server_side_encryption_configuration` with `sse_algorithm = "aws:kms"`.
