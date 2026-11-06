# Lab 15 - Kubernetes Cluster Provisioning with Amazon EKS

**Program:** Executive MBA in DevOps Engineering  
**Platform / Environment:** GitHub Codespaces (AWS Academy / AWS Cloud)  
**Language / Stack:** Terraform 1.9+, AWS Provider, Amazon EKS, Multi-AZ VPC, `kubectl`  
**Estimated Duration:** 30 minutes  

---

## 🎯 Lab Objectives

Learn how to design and provision enterprise container orchestration platforms using Amazon EKS:
1. Architect a resilient multi-AZ VPC network topology distributed across 3 Availability Zones (`us-east-1a`, `us-east-1b`, `us-east-1c`).
2. Integrate pre-approved institutional IAM roles (`LabRole`) via data sources for Control Plane and Worker Nodes.
3. Provision managed Kubernetes control planes (`aws_eks_cluster`) and elastic Node Groups (`aws_eks_node_group`) allocated across public subnets for rapid node registration.
4. Authenticate `kubectl` client tooling via AWS CLI and audit cluster node health.

---

## 📋 Prerequisites & Materials

- Active **AWS Academy** credentials configured in `~/.aws/credentials`.
- `aws` and `kubectl` binaries available in your Codespaces terminal.
- Terminal navigated to the lab directory:
  ```bash
  cd lab15-eks
  ```

---

## 🚀 Step-by-Step Guided Walkthrough

### Step 1: Review Network and Cluster Architecture in `main.tf`
Open `main.tf` and analyze core blocks:
- **VPC and Subnets:** Creates a `10.0.0.0/16` VPC with 3 public and 3 private subnets tagged for Kubernetes ingress discovery.
- **IAM Data Source:** Reuses standard educational roles:
  ```hcl
  data "aws_iam_role" "lab_role" {
    name = "LabRole"
  }
  ```
- **EKS Cluster and Node Group:**
  ```hcl
  resource "aws_eks_cluster" "eks_cluster" {
    name     = var.cluster_name
    role_arn = data.aws_iam_role.lab_role.arn
    version  = var.eks_version

    vpc_config {
      subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
    }
  }

  resource "aws_eks_node_group" "eks_node_group" {
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_group_name = "eks-node-group"
    node_role_arn   = data.aws_iam_role.lab_role.arn
    subnet_ids      = aws_subnet.public_subnets[*].id # Avoids private subnet NAT Gateway timeouts

    scaling_config {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }
  }
  ```

### Step 2: Lifecycle Provisioning
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Note:* Cloud provisioning of managed Kubernetes control plane and worker nodes typically requires 10 to 15 minutes.

---

## 🧪 Validation & Acceptance Criteria

1. **Configure Local Kubeconfig Context:**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name eks-cluster
   ```
2. **Audit Worker Node Readiness:**
   ```bash
   kubectl get nodes -o wide
   ```
   *Acceptance Criteria:* 2 EC2 worker nodes must report status `Ready`.
3. **Audit Core System Pods:**
   ```bash
   kubectl get pods -n kube-system
   ```
   *Acceptance Criteria:* `coredns`, `kube-proxy`, and `aws-node` pods are `Running`.

---

## 🧹 Cleanup

Teardown cluster resources to prevent extensive budget burn:
```bash
terraform destroy -auto-approve
cd ..
```
*Teardown operations typically take 8 to 12 minutes.*

---

## 💡 Supplementary Challenges

1. **Deploy Sample Nginx Workload:** Create a deployment (`kubectl create deployment web --image=nginx --replicas=2`) and verify load distribution across worker nodes.
2. **Cluster Auto-Scaling:** Adjust `desired_size = 3` in `main.tf`, re-apply, and observe dynamic node pool expansion.
