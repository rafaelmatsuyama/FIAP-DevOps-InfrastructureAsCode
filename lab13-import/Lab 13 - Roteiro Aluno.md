# Lab 13 - Importação de Infraestrutura Existente (Terraform Import)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, `terraform import`  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Aprender a incorporar recursos legados criados manualmente (*brownfield*) sob a governança do Terraform sem tempo de inatividade:
1. Compreender os desafios de absorção de infraestruturas legadas em pipelines de IaC.
2. Declarar blocos de recursos esqueleto no `main.tf` para acomodar o estado importado.
3. Executar o comando `terraform import` associando o identificador físico da nuvem (`i-0...`) ao endereço lógico HCL.
4. Auditar e eliminar divergências de configuração (*drift reconciliation*) via `terraform state show` e `terraform plan`.
5. Modificar e descomissionar recursos importados de forma totalmente automatizada.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Uma instância EC2 existente na conta (ou criada via console/CLI com tag `Instância Legada`).
- Terminal posicionado no diretório:
  ```bash
  cd lab13-import
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Identificação do Recurso Físico
Capture o ID da instância existente na AWS:
```bash
INSTANCE_ID=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].InstanceId" --output text)
echo "ID Identificado: $INSTANCE_ID"
```

### Passo 2: Estruturação do Bloco Esqueleto no `main.tf`
Abra `main.tf` e certifique-se de que o recurso alvo está declarado:
```hcl
resource "aws_instance" "example" {
  # Os atributos reais serão conciliados após o import
  ami           = "ami-placeholder"
  instance_type = "t2.micro"

  tags = {
    Name = "Recurso Brownfield"
  }
}
```

### Passo 3: Executar a Importação de Estado
```bash
terraform init
terraform import aws_instance.example $INSTANCE_ID
```
*O Terraform consulta a API da AWS, constrói a representação JSON do recurso e grava no arquivo local `terraform.tfstate` com mensagem `Import successful!`.*

### Passo 4: Reconciliação de Drift (Zero-Drift Convergence)
Inspecione os atributos reais gravados no state:
```bash
terraform state show aws_instance.example
```
Compare com o planejamento:
```bash
terraform plan
```
*Edite os atributos (`ami`, `instance_type`, `tags`) no `main.tf` até que o planejamento indique estritamente:*
`No changes. Your infrastructure matches the configuration.`

---

## 🧪 Validação & Critérios de Aceite

1. **Validação de Governança Ativa:**
   Altere a tag `Name` no `main.tf` para `"Instância Importada e Gerenciada"` e execute:
   ```bash
   terraform apply -auto-approve
   ```
2. **Confirmação via AWS CLI:**
   ```bash
   aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value|[0]" --output text
   ```
   *Critério de Aceite:* A tag retornada deve ser `Instância Importada e Gerenciada`, provando que o recurso manual está sob controle do código.

---

## 🧹 Cleanup

Descomissione o recurso governado pelo Terraform:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Bloco `import` Declarativo (Terraform 1.5+):** Em vez do comando CLI manual, explore a sintaxe declarativa moderna do Terraform:
   ```hcl
   import {
     to = aws_instance.example
     id = "i-0123456789abcdef0"
   }
   ```
   Execute `terraform plan -generate-config-out=generated.tf` e observe como o Terraform gera o HCL correspondente automaticamente.
2. **Importação de Security Group:** Realize a importação de um grupo de segurança existente (`aws_security_group`) com suas respectivas regras de firewall.
