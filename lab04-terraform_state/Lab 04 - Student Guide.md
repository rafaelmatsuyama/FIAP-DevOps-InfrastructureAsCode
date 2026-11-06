# Lab 04 - Remote State Management (S3 Backend & State Locking)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS S3, DynamoDB, Remote State Backend  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Learn how to implement a secure, collaborative cloud infrastructure architecture using remote state management:
1. Provision an encrypted AWS S3 bucket and a dedicated DynamoDB table for distributed state locking.
2. Configure Terraform remote backend and execute deterministic state migration (`terraform init -migrate-state`).
3. Validate atomic state locks (*State Locking*) preventing race conditions and concurrent team overwrites.
4. Manage lifecycle safeguard policies (`prevent_destroy`) and clean rollback procedures.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- Integrated terminal located in the lab directory:
  ```bash
  cd lab04-terraform_state
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Unique S3 Identifier Configuration
Because AWS S3 bucket names must be globally unique:
1. Open `main.tf` and replace `-rafael-matsuyama123` with a custom unique suffix (e.g. `-your-name-rm`).
2. Open `backend.tf` and match the bucket name parameter.

### Step 2: Provision Storage Infrastructure (Local Phase)
Because the S3 bucket and DynamoDB table do not exist yet, disable the remote backend declaration temporarily to create them via local state:
```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply -auto-approve
```
*Terraform provisions the versioned S3 bucket and the DynamoDB table with `LockID` primary key.*

### Step 3: Enable Remote Backend and Migrate State
Now that the physical storage resources exist:
1. Re-enable the backend file:
   ```bash
   mv backend.tf.disabled backend.tf
   ```
2. Trigger the migration workflow:
   ```bash
   terraform init -migrate-state
   ```
3. When prompted (`Do you want to copy existing state to the new backend?`), type `yes` and press `Enter`.

---

## 🧪 Validation & Acceptance Criteria

1. **Validate Distributed State Lock:**
   Execute an execution plan:
   ```bash
   terraform plan
   ```
   *Acceptance Criteria:* Terminal logs display explicit `Acquiring state lock` and `Releasing state lock` notifications.
2. **Audit Remote S3 Objects:**
   Query the bucket using the AWS CLI:
   ```bash
   aws s3 ls s3://YOUR-BUCKET-NAME/
   ```
   *Acceptance Criteria:* The `terraform.tfstate` key must be listed inside the remote bucket.

---

## 🧹 Cleanup

To teardown the state infrastructure cleanly without backend deadlocks:

1. **Disable Lifecycle Safeguard:**
   In `main.tf`, change `prevent_destroy = false` (or remove `lifecycle` blocks).
2. **Revert to Local Backend:**
   ```bash
   mv backend.tf backend.tf.disabled
   terraform init -migrate-state
   ```
   *Confirm with `yes` to move state back to your local filesystem.*
3. **Destroy Cloud Resources:**
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```

---

## 💡 Supplementary Challenges

1. **Simulate Concurrent Lock Collision:** Open two terminal tabs in Codespaces. In terminal 1, run `terraform apply` and leave it waiting at the prompt. In terminal 2, run `terraform plan`. Observe the *Error acquiring the state lock* exception.
2. **KMS Server-Side Encryption:** Configure server-side encryption with AWS KMS managed keys (`aws_kms_key`) on the state bucket.
