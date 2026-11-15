# Lab 02 - Local Provisioning (Terraform + Docker in Codespaces)

**Program / Course:** Executive MBA in DevOps Engineering — Infrastructure as Code (IaC)  
**Platform / Environment:** GitHub Codespaces (Linux DevContainer with Docker socket)  
**Language / Stack:** Terraform 1.9+, Docker Provider (`kreuzwerker/docker`), Nginx  
**Estimated Duration:** 20 minutes  

---

## 🎯 Lab Objectives

Learn how to manage real containerized compute infrastructure using declarative Infrastructure as Code (IaC) before provisioning paid public cloud workloads.

**Corporate Scenario (FinCorp Developer Experience):**  
Developers and QA engineers at *FinCorp* waste hours spinning up local web runtimes with manual `docker run` commands and inconsistent flags across workstations (*"it works on my machine"*). Your mission is to standardize Nginx container provisioning via Terraform, guaranteeing reproducibility, state tracking, and clean teardown.

**Skills Acquired:**
1. Declare community-maintained external providers via Terraform Registry (`kreuzwerker/docker`).
2. Manage the end-to-end lifecycle of Docker images and containers (`docker_image` and `docker_container`).
3. Inspect complex state attributes (port bindings, runtime IDs, bridge network settings) and export `outputs`.
4. Validate port forwarding and HTTP connectivity inside GitHub Codespaces.

---

## 📋 Prerequisites & Materials

- Active workspace in **GitHub Codespaces** (Docker daemon and Terraform 1.9+ active via DevContainer).
- Manifest provided in this lab: [`main.tf`](./main.tf).
- Integrated terminal located in the lab directory:
  ```bash
  cd lab02-docker_basics
  ```

> [!TIP]
> **🚀 Zero-Friction Sandbox (Zero Cloud Cost):**  
> This laboratory uses the built-in Codespaces Docker socket (`docker-outside-of-docker`). No AWS Academy credentials are required yet.

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Declarative Manifest `main.tf`
Open [`main.tf`](./main.tf) and analyze the declared resources and outputs:
```hcl
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx_web" {
  image = docker_image.nginx.image_id
  name  = "fiap-web-server"

  ports {
    internal = 80
    external = 8080
  }
}
```
- **`required_providers`:** Connects to the community registry `kreuzwerker/docker` (`~> 3.0.1`).
- **`docker_image.nginx`:** Pulls `nginx:latest` if not cached locally. Setting `keep_locally = false` ensures `terraform destroy` also removes the local image.
- **`docker_container.nginx_web`:** References `docker_image.nginx.image_id` (implicit DAG dependency) and maps internal port `80` to host port `8080`.
- **`output "web_url"` & `output "container_id"`:** Expose the local HTTP endpoint and container runtime ID after provisioning.

### Step 2: Initialize Provider
In the terminal, run:
```bash
terraform init
```

> **Expected Output:**
> ```text
> Initializing the backend...
> Initializing provider plugins...
> - Finding kreuzwerker/docker versions matching "~> 3.0.1"...
> - Installing kreuzwerker/docker v3.0.2...
> - Installed kreuzwerker/docker v3.0.2 (self-signed, key ID BD080C4571C6104C)
>
> Terraform has been successfully initialized!
> ```

### Step 3: Preview Execution Plan
Generate the execution plan:
```bash
terraform plan
```

> **Expected Output (Summary):**
> ```text
> Plan: 2 to add, 0 to change, 0 to destroy.
>
> Changes to Outputs:
>   + container_id = (known after apply)
>   + web_url      = "http://localhost:8080"
> ```

### Step 4: Apply Configuration
Pull the image and launch the container:
```bash
terraform apply -auto-approve
```

> **Expected Output:**
> ```text
> docker_image.nginx: Creating...
> docker_image.nginx: Creation complete after ...
> docker_container.nginx_web: Creating...
> docker_container.nginx_web: Creation complete after ...
>
> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
>
> Outputs:
> container_id = "..."
> web_url = "http://localhost:8080"
> ```

---

## 🧪 Validation & Acceptance Criteria

Validate the running infrastructure with the following checks:

1. **Verify via Docker CLI:**
   Inspect active containers:
   ```bash
   docker ps --filter "name=fiap-web-server"
   ```
   > **Expected Output:**
   > ```text
   > CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                  NAMES
   > a1b2c3d4e5f6   <image_id>     "/docker-entrypoint.…"   5 seconds ago   Up 4 seconds   0.0.0.0:8080->80/tcp   fiap-web-server
   > ```

2. **HTTP Connectivity Check:**
   Execute a curl request directly against localhost:
   ```bash
   curl -s http://localhost:8080 | grep "Welcome to nginx"
   ```
   > **Expected Output:**
   > ```text
   > <title>Welcome to nginx!</title>
   > <h1>Welcome to nginx!</h1>
   > ```

   > [!TIP]
   > **🌐 Browser Preview (Codespaces Ports):**  
   > In GitHub Codespaces, open the **Ports** tab (next to *Terminal*), locate port **8080**, and click the globe icon (**Open in Browser**) to view the Nginx welcome page over the forwarded Codespaces URL.

3. **Outputs & Advanced State Inspection:**
   ```bash
   terraform output
   terraform show
   ```
   *Acceptance Criteria:* `terraform output` prints `container_id` and `web_url`; `terraform show` displays dynamic runtime attributes including `network_data`, `ip_address`, `gateway`, and `ports`.

---

## 🧹 Cleanup

Tear down the container, clear the local image cache, and release host port `8080`:
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
*Run `docker ps` to verify the container stopped (and `docker images` to confirm `nginx:latest` was removed due to `keep_locally = false`).*

---

## 💡 Supplementary Challenges

1. **Custom HTML Injection (`volumes`):** Create a custom local `index.html` file in the lab directory and mount it into `/usr/share/nginx/html/index.html` using a `volumes` block on `docker_container` (hint: use `host_path = abspath("${path.module}/index.html")`, as the Docker daemon requires an absolute host path).
2. **Input Variables (`variables.tf`):** Create a `variables.tf` file declaring `external_port` (type `number`, default `8080`) with a validation rule (`1024` to `65535`) and wire it into the `ports` block in `main.tf`.
