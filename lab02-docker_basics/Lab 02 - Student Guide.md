# Lab 02 - Local Provisioning (Terraform + Docker in Codespaces)

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (Linux DevContainer with Docker socket)  
**Language / Stack:** Terraform 1.9+, Docker Provider (`kreuzwerker/docker`), Nginx  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Learn how to manage real containerized compute infrastructure using declarative Infrastructure as Code (IaC):
1. Declare community-maintained external providers via Terraform Registry (`kreuzwerker/docker`).
2. Manage the end-to-end lifecycle of Docker images and containers (`docker_image` and `docker_container`).
3. Inspect complex state attributes (port bindings, runtime IDs, bridge network settings).
4. Validate port forwarding and connectivity inside GitHub Codespaces.

---

## 📋 Prerequisites & Materials

- Active workspace in **GitHub Codespaces** (Docker daemon and Terraform active via DevContainer).
- Integrated terminal located in the lab directory:
  ```bash
  cd lab02-docker_basics
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Declarative Manifest `main.tf`
Open `main.tf` and analyze the declared components:
- **`required_providers`:** Connects to the community registry `kreuzwerker/docker`.
- **`resource "docker_image" "nginx"`:** Declarative directive to fetch `nginx:latest` from Docker Hub if not present locally.
- **`resource "docker_container" "nginx_web"`:** Provisions and starts the container referencing the image ID (`docker_image.nginx.image_id`), binding internal port 80 to external host port 8080.

### Step 2: Initialize Provider
In the terminal, run:
```bash
terraform init
```
*Terraform downloads the Docker provider binary and locks provider versions.*

### Step 3: Preview Execution Plan
Generate the execution plan:
```bash
terraform plan
```
*Verify that Terraform plans to create 2 resources (`Plan: 2 to add, 0 to change, 0 to destroy`).*

### Step 4: Apply Configuration
Provision the image and launch the container:
```bash
terraform apply -auto-approve
```

---

## 🧪 Validation & Acceptance Criteria

Validate the running infrastructure with the following checks:

1. **Verify via Docker CLI:**
   Inspect active containers:
   ```bash
   docker ps --filter "name=fiap-web-server"
   ```
   *Acceptance Criteria:* `fiap-web-server` must display status `Up` with port binding `0.0.0.0:8080->80/tcp`.
2. **HTTP Connectivity Check:**
   Execute a curl request directly against localhost:
   ```bash
   curl -s http://localhost:8080 | grep "Welcome to nginx"
   ```
   *Acceptance Criteria:* Command returns valid HTML containing `<title>Welcome to nginx!</title>`.
3. **Advanced State Inspection:**
   Inspect the detailed state recorded by Terraform:
   ```bash
   terraform show
   ```
   *Notice dynamic runtime attributes including `ip_address`, `gateway`, and container network mappings.*

---

## 🧹 Cleanup

Tear down the container and release host ports:
```bash
terraform destroy -auto-approve
cd ..
```
*Run `docker ps` to verify that the container was stopped and removed.*

---

## 💡 Supplementary Challenges

1. **Custom HTML Injection:** Add a volume mount in `docker_container` binding a custom local `index.html` file into `/usr/share/nginx/html/`.
2. **Input Variables:** Introduce a `variables.tf` file to parameterize the external port (`8080`) as a configurable input.
