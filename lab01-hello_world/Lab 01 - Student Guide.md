# Lab 01 - My First Provisioning (Codespaces + Hello World)

**Program / Course:** Executive MBA in DevOps Engineering — Infrastructure as Code (IaC)  
**Platform / Environment:** GitHub Codespaces (Linux DevContainer)  
**Language / Stack:** Terraform 1.9+ (Providers `local` & `random`)  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Master the core declarative lifecycle of HashiCorp Terraform and local state management before provisioning paid public cloud resources.

**Corporate Scenario (FinCorp Platform Engineering):**  
The platform engineering team at *FinCorp* needs to eliminate fragile imperative scripts that manually generate server configuration files and cause drift across environments. Your mission in this opening lab is to validate Terraform's declarative engine in zero-cost sandbox mode by generating a unique random identifier and a deterministic artifact on disk.

**Skills Acquired:**
1. Initialize declarative providers and generate dependency lock files (`terraform init`).
2. Inspect deterministic execution plans before mutating infrastructure (`terraform plan`).
3. Apply manifests and audit local state representation (`terraform.tfstate`).
4. Prove **Idempotency** guarantees and perform controlled teardown (`terraform destroy`).

---

## 📋 Prerequisites & Materials

- Repository opened in **GitHub Codespaces** (pre-configured with Terraform 1.9+ via DevContainer).
- Manifest provided in this lab: [`main.tf`](./main.tf).
- Integrated bash terminal located in the lab folder:
  ```bash
  cd lab01-hello_world
  ```

> [!TIP]
> **🚀 Zero-Friction Sandbox (Zero Cloud Cost):**  
> This laboratory uses only the local `hashicorp/local` and `hashicorp/random` providers. No AWS Academy credentials are required yet.

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Inspect the Declarative Manifest
Open [`main.tf`](./main.tf) in the `lab01-hello_world` directory and review the configuration blocks:
- **`terraform`:** Specifies minimum engine version (`>= 1.9.0`) and provider constraints (`local` and `random`).
- **`random_id.unique_suffix`:** Generates a 4-byte random hex identifier (8 characters) to simulate unique infrastructure suffixes.
- **`local_file.hello_fiap`:** Creates a local text file interpolating `${random_id.unique_suffix.hex}`, establishing an implicit dependency in the DAG.

### Step 2: Initialize the Workspace
In the terminal, initialize the Terraform working directory:
```bash
terraform init
```

> **Expected Output:**
> ```text
> Initializing the backend...
> Initializing provider plugins...
> - Finding hashicorp/local versions matching "~> 2.5.1"...
> - Finding hashicorp/random versions matching "~> 3.6.0"...
> - Installing hashicorp/local v2.5.3...
> - Installing hashicorp/random v3.6.3...
> Terraform has created a lock file .terraform.lock.hcl to record the provider
> selections it made above.
>
> Terraform has been successfully initialized!
> ```

### Step 3: Generate the Execution Plan
Run a plan to preview the actions Terraform intends to take before modifying anything:
```bash
terraform plan
```

> **Expected Output (Relevant Snippet):**
> ```text
> Terraform will perform the following actions:
>
>   # local_file.hello_fiap will be created
>   + resource "local_file" "hello_fiap" {
>       + content  = (known after apply)
>       + filename = "./hello_world.txt"
>       + id       = (known after apply)
>     }
>
>   # random_id.unique_suffix will be created
>   + resource "random_id" "unique_suffix" {
>       + byte_length = 4
>       + hex         = (known after apply)
>       + id          = (known after apply)
>     }
>
> Plan: 2 to add, 0 to change, 0 to destroy.
> ```

### Step 4: Apply Changes
Provision the local resources on disk:
```bash
terraform apply
```
*When prompted for confirmation (`Enter a value:`), type `yes` and press `Enter`.*

> **Expected Output:**
> ```text
> random_id.unique_suffix: Creating...
> random_id.unique_suffix: Creation complete after 0s [id=...]
> local_file.hello_fiap: Creating...
> local_file.hello_fiap: Creation complete after 0s [id=...]
>
> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
> ```

> [!WARNING]
> **State Governance (`terraform.tfstate`):**  
> After `apply`, Terraform persists `terraform.tfstate` locally. In real cloud projects, **never** commit `.tfstate` files to Git (our `.gitignore` blocks them automatically), as state files store full resource metadata and potential plaintext secrets.

---

## 🧪 Validation & Acceptance Criteria

Execute the following checks to confirm successful completion:

1. **Verify File Generation:**
   Check that `hello_world.txt` was created with the unique random suffix:
   ```bash
   cat hello_world.txt
   ```
   > **Expected Output:**
   > ```text
   > Hello, FIAP DevOps Engineer! Unique infrastructure identifier: 68afa96a
   > ```
   *(The 8-character hexadecimal suffix will be randomly generated on your run).*

2. **Audit State Metadata (`terraform.tfstate`):**
   Inspect the recorded state attributes managed by Terraform:
   ```bash
   terraform show
   ```
   *Acceptance Criteria:* Both `local_file.hello_fiap` and `random_id.unique_suffix` display resolved attributes, including SHA256/MD5 checksums and the generated `hex` value.

3. **Validate Idempotency:**
   Re-run the apply command without modifying code:
   ```bash
   terraform apply -auto-approve
   ```
   > **Expected Output:**
   > ```text
   > No changes. Your infrastructure matches the configuration.
   >
   > Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
   > ```
   *Acceptance Criteria:* Zero changes applied, proving that current state matches the desired declaration.

---

## 🧹 Cleanup

Teardown provisioned resources to complete the lifecycle:
```bash
terraform destroy -auto-approve
cd ..
```

> **Expected Output:**
> ```text
> Plan: 0 to add, 0 to change, 2 to destroy.
> ...
> Destroy complete! Resources: 2 destroyed.
> ```
*Run `ls` to confirm that `hello_world.txt` was removed automatically from the directory.*

---

## 💡 Supplementary Challenges

1. **Modify Byte Length (`ForceNew` / `-/+`):** Update `byte_length = 4` to `byte_length = 8` in `random_id.unique_suffix`. Run `terraform plan` and observe how Terraform cascades recreation (`-/+ destroy and then create replacement`) to the dependent file.
2. **Structured Local File (`jsonencode`):** Add a second `local_file` resource targeting `status.json` using Terraform's native `jsonencode()` function with a mocked JSON payload, then apply only that incremental delta.
