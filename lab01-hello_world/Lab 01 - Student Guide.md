# Lab 01 - My First Provisioning (Codespaces + Hello World)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (Linux DevContainer)  
**Language / Stack:** Terraform 1.9+ (Providers `local` & `random`)  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Master the core lifecycle of HashiCorp Terraform and understand declarative Infrastructure as Code (IaC):
1. Initialize declarative providers and inspect dependency graphs (`terraform init`).
2. Generate deterministic execution plans without modifying real-world state (`terraform plan`).
3. Apply manifests and audit local state representation (`terraform.tfstate`).
4. Validate idempotency guarantees and perform controlled environment teardown (`terraform destroy`).

---

## 📋 Prerequisites & Materials

- Repository opened in **GitHub Codespaces** (pre-configured with Terraform 1.9+ via DevContainer).
- Integrated bash terminal located in the lab folder:
  ```bash
  cd lab01-hello_world
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Inspect the Declarative Manifest
Open `main.tf` in the `lab01-hello_world` directory and review the configuration blocks:
- **`terraform`:** Specifies minimum engine and provider versions (`local` and `random`).
- **`random_id.unique_suffix`:** Generates a 4-byte random hex string to simulate dynamic resource naming.
- **`local_file.hello_fiap`:** Creates a local text file interpolating the generated random suffix.

### Step 2: Initialize the Workspace
In the terminal, initialize the Terraform working directory:
```bash
terraform init
```
*Terraform reads `main.tf`, downloads official provider plugins from the Terraform Registry, and creates the hidden `.terraform/` cache folder.*

### Step 3: Generate the Execution Plan
Run a plan to preview the actions Terraform intends to take:
```bash
terraform plan
```
*Review the terminal output: Terraform displays `Plan: 2 to add, 0 to change, 0 to destroy` with green `+` prefixes denoting additive atomic actions.*

### Step 4: Apply Changes
Provision the local resources:
```bash
terraform apply
```
*When prompted for confirmation (`Enter a value:`), type `yes` and press `Enter`.*

---

## 🧪 Validation & Acceptance Criteria

Execute the following checks to confirm successful completion:

1. **Verify File Generation:**
   Check that `hello_world.txt` was created with the unique random suffix:
   ```bash
   cat hello_world.txt
   ```
2. **Audit State Metadata (`terraform.tfstate`):**
   Inspect the recorded state attributes managed by Terraform:
   ```bash
   terraform show
   ```
   *Notice how Terraform persists resource attributes in structured JSON format.*
3. **Validate Idempotency:**
   Re-run the apply command without modifying code:
   ```bash
   terraform apply -auto-approve
   ```
   *Acceptance Criteria:* The output must confirm `Apply complete! Resources: 0 added, 0 changed, 0 destroyed`, proving that current state matches the desired declaration.

---

## 🧹 Cleanup

Teardown provisioned resources to complete the lifecycle:
```bash
terraform destroy -auto-approve
cd ..
```
*Confirm that `hello_world.txt` was removed from the directory.*

---

## 💡 Supplementary Challenges

1. **Modify Byte Length:** Update `byte_length = 4` to `byte_length = 8` in `random_id.unique_suffix`. Run `terraform plan` and notice how Terraform marks the resource for destruction and recreation (`-/+`).
2. **Additional Local File:** Add a second `local_file` resource generating a mock `status.json` payload, apply it, and verify the resulting state.
