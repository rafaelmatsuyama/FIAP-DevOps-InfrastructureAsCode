# Lab 06 - Consultas Dinâmicas (Uso de Data Sources no Terraform)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Data Sources  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a desacoplar valores estáticos de infraestrutura através de consultas dinâmicas via Data Sources:
1. Compreender a diferença conceitual e de ciclo de vida entre recursos gerenciados (`resource`) e fontes de dados somente leitura (`data`).
2. Configurar filtros complexos de busca de imagens de SO diretamente na API da AWS (`aws_ami`).
3. Resolver determinísticamente a versão mais recente do Ubuntu 20.04/22.04 mantida pela Canonical.
4. Provisionar instâncias EC2 acopladas ao resultado dinâmico do Data Source.

---

## 📋 Pré-requisitos & Materiais

- Credenciais da **AWS Academy** ativas em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab06-datasource
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Bloco `data "aws_ami"` no `main.tf`
Abra `main.tf` e observe como a consulta à Canonical é parametrizada:
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical Official Account ID
}
```
*O Terraform consulta o catálogo oficial em tempo de planejamento e captura o ID da AMI mais recente.*

### Passo 2: Referência Cruzada na Instância
Observe a injeção do ID dinâmico no recurso `aws_instance`:
```hcl
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "Data Sources Example"
  }
}
```

### Passo 3: Execução do Ciclo de Vida
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Repare que no output do `terraform plan` o ID literal da AMI (ex: `ami-0...`) é exibido antes do provisionamento real.*

---

## 🧪 Validação & Critérios de Aceite

1. **Validação via AWS CLI:**
   Consulte a imagem associada à instância criada:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Data Sources Example'" --query "Reservations[*].Instances[*].[InstanceId,ImageId,State.Name]" --output table
   ```
   *Critério de Aceite:* O `ImageId` retornado deve bater exatamente com a AMI resolvida pelo Data Source.
2. **Inspeção de Metadados do Data Source:**
   ```bash
   terraform state show data.aws_ami.ubuntu
   ```
   *Critério de Aceite:* O comando exibe os metadados completos da imagem (arquitetura `x86_64`, root device `ebs`, etc.).

---

## 🧹 Cleanup

Desprovisione a instância para evitar cobranças:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Consulta de VPC Padrão:** Adicione um bloco `data "aws_vpc" "default" { default = true }` e exporte o `id` e o `cidr_block` da VPC padrão da conta via `output`.
2. **Filtro para Amazon Linux 2023:** Modifique os filtros do `data "aws_ami"` para buscar a AMI oficial mais recente do Amazon Linux 2023 sob o owner `137112412989` (Amazon).
