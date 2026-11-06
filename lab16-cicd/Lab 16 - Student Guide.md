# Lab 16 - CI/CD Pipeline for IaC with GitHub Actions & AWS

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Actions + GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, GitHub Actions, Trivy Security Scanner, AWS EC2, S3 State Sync  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Build and operate an automated enterprise CI/CD pipeline for GitOps infrastructure delivery:
1. Configure multi-stage interdependent workflows in GitHub Actions (`.github/workflows/terraform-pipeline.yml`).
2. Implement strict DevSecOps Quality Gates: format enforcement (`fmt`), syntax compilation (`validate`), and static vulnerability scanning (`Trivy`).
3. Manage temporary cloud credentials securely via GitHub Actions Secrets.
4. Orchestrate automated plan and apply execution against live AWS accounts with remote S3 state sync.
5. Provide controlled manual teardown triggers via `workflow_dispatch`.

---

## 📋 Prerequisites & Materials

- Personal repository fork on GitHub with Actions enabled.
- Active **AWS Academy** credentials added under **Settings → Secrets and variables → Actions**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN`
  - `AWS_REGION` (`us-east-1`)
- Terminal navigated to the lab directory:
  ```bash
  cd lab16-cicd
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Enable Actions and Register Secrets
1. In your personal fork on GitHub, navigate to the **Actions** tab and enable workflows.
2. Go to **Settings → Secrets and variables → Actions** and add the 4 required AWS credentials.

### Step 2: Review Pipeline Architecture
Examine `.github/workflows/terraform-pipeline.yml` at the repository root:
- **Job 1 (Quality Gate & Lint):** Executes `terraform fmt -check`, `terraform validate`, and static security scanning with `aquasecurity/trivy-action`.
- **Job 2 (Deploy / Destroy on AWS):** Runs conditionally on the `main` branch after Job 1 succeeds (`needs: quality_and_security`). Pulls/pushes state to S3 and executes plans.

### Step 3: Trigger Workflow via Git Push (GitOps)
Make a minor cosmetic edit in `lab16-cicd/main.tf` (e.g. edit the HTML banner in `user_data`), commit, and push:
```bash
git add lab16-cicd/main.tf
git commit -m "feat(ci): trigger automated deployment pipeline"
git push origin main
```
*Monitor workflow progression live under the Actions tab.*

---

## 🧪 Validation & Acceptance Criteria

1. **Verify Workflow Logs:**
   Open the workflow run details and verify that:
   - Job `1. Quality Gate & Lint` completes green with 0 security findings.
   - Job `2. Deploy / Destroy on AWS` completes apply and returns `web_url`.
2. **HTTP Endpoint Verification:**
   Query the provisioned IP address:
   ```bash
   curl -I http://PIPELINE_OUTPUT_IP
   ```
   *Acceptance Criteria:* Status `HTTP/1.1 200 OK` returned by Nginx.

---

## 🧹 Cleanup

### Method 1: Automated Teardown via GitHub Actions (Recommended)
1. In your GitHub repository, open the **Actions** tab.
2. Select **Terraform CI/CD Pipeline (Lab 16)**.
3. Click **Run workflow**, choose action **`destroy`**, and run.

### Method 2: Teardown via Terminal
```bash
cd lab16-cicd
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 cp s3://tfstate-lab16-${ACCOUNT_ID}/terraform.tfstate terraform.tfstate
terraform destroy -auto-approve
cd ..
```

---

## 💡 Supplementary Challenges

1. **Blocking Quality Gate:** Update the workflow to set Trivy `exit-code: 1`. Introduce an overly permissive security group rule (`0.0.0.0/0` on port 22) and verify that the pipeline fails and blocks deployment.
2. **GitHub Environment Protection:** Add an approval gate using GitHub Environments requiring manual review before triggering production apply.
