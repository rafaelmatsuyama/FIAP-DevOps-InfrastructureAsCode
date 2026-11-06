# Lab 15 - Provisionamento de Cluster Kubernetes com Amazon EKS

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, Amazon EKS, VPC Multi-AZ, `kubectl`  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a projetar e provisionar uma infraestrutura corporativa para orquestração de containers com Amazon EKS:
1. Arquitetar uma topologia de rede VPC multi-AZ resiliente distribuída em 3 Availability Zones (`us-east-1a`, `us-east-1b`, `us-east-1c`).
2. Integrar permissões IAM do ecossistema educacional (`LabRole`) via data sources para Control Plane e Worker Nodes.
3. Provisionar o cluster gerenciado (`aws_eks_cluster`) e o Node Group elástico (`aws_eks_node_group`) alocado em subnets públicas para registro acelerado dos nós.
4. Autenticar o cliente `kubectl` via AWS CLI e auditar a prontidão dos nós de computação.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Binários do `aws` e `kubectl` disponíveis no terminal do Codespaces.
- Terminal posicionado no diretório:
  ```bash
  cd lab15-eks
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise da Arquitetura de Rede e EKS no `main.tf`
Abra `main.tf` e observe as definições estruturais:
- **VPC e Subnets:** Provisiona uma VPC `10.0.0.0/16` com 3 subnets públicas e 3 privadas com tags de discoverability para Kubernetes.
- **Data Source IAM:** Reutiliza a role institucional pré-aprovada:
  ```hcl
  data "aws_iam_role" "lab_role" {
    name = "LabRole"
  }
  ```
- **Control Plane e Node Group:**
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
    subnet_ids      = aws_subnet.public_subnets[*].id # Alocação em subnets publicas evita timeout sem NAT Gateway

    scaling_config {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }
  }
  ```

### Passo 2: Execução do Provisionamento
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Atenção:* O provisionamento do cluster gerenciado EKS e dos nós leva em média de 10 a 15 minutos na AWS.

---

## 🧪 Validação & Critérios de Aceite

1. **Atualização do Kubeconfig Local:**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name eks-cluster
   ```
2. **Inspeção de Prontidão dos Worker Nodes:**
   ```bash
   kubectl get nodes -o wide
   ```
   *Critério de Aceite:* Devem figurar 2 nós computacionais com status `Ready`.
3. **Auditoria de Pods de Sistema:**
   ```bash
   kubectl get pods -n kube-system
   ```
   *Critério de Aceite:* Pods `coredns`, `kube-proxy` e `aws-node` com status `Running`.

---

## 🧹 Cleanup

Para evitar consumo severo do orçamento de nuvem, destrua o cluster:
```bash
terraform destroy -auto-approve
cd ..
```
*A destruição do cluster e dos nós pode levar de 8 a 12 minutos.*

---

## 💡 Desafios Complementares

1. **Deploy de Workload Nginx:** Crie um manifesto simples de deployment (`kubectl create deployment web --image=nginx --replicas=2`) e valide a distribuição dos pods entre os dois nós de trabalho.
2. **Cluster AutoScaling:** Altere `desired_size = 3` no `main.tf`, reaplique o plano e observe a adição dinâmica do novo nó ao cluster.
