# Lab 05 - Refatoração e Modularização (Criando Módulos no Terraform)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Módulos HCL  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a desacoplar infraestruturas monolíticas através do desenvolvimento de módulos reutilizáveis:
1. Compreender o padrão de design e encapsulamento em módulos Terraform (*root* e *child modules*).
2. Declarar contratos de entrada (`variables.tf`) e saídas padronizadas (`outputs.tf`).
3. Chamar e instanciar módulos locais parametrizados no manifesto principal (`main.tf`).
4. Reexportar outputs de recursos encapsulados para consumo pelo chamador raiz.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab05-refactoring
  ```

---

## 🏗️ Estrutura Arquitetural do Módulo

```text
lab05-refactoring/
├── main.tf                 # Root module (orquestrador de chamadas)
└── modules/
    └── ec2/                # Child module reutilizável
        ├── main.tf         # Recurso aws_instance parametrizado
        ├── variables.tf    # Contrato de entrada (inputs)
        └── outputs.tf      # Contrato de saída (outputs)
```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Inspeção dos Contratos do Módulo Filho
Examine os arquivos dentro de `modules/ec2/`:
- **`variables.tf`:** Define as variáveis obrigatórias (`ami`, `instance_type`, `security_groups` e `name`) com descrições semânticas.
- **`main.tf`:** Cria o recurso `aws_instance.example` mapeado às variáveis recebidas (`ami = var.ami`).
- **`outputs.tf`:** Expõe o atributo `aws_instance.example.public_ip` para fora do escopo do módulo.

### Passo 2: Análise da Chamada no Módulo Raiz
Abra o `main.tf` raiz e revise o bloco de chamada:
```hcl
module "ec2_instance" {
  source = "./modules/ec2"

  ami             = "ami-0de716d6197524dd9"
  instance_type   = "t2.micro"
  security_groups = ["allow_ssh_http"]
  name            = "Terraform Module Example"
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
```

### Passo 3: Inicialização e Registro de Módulos
Sempre que um novo módulo local é incluído, inicialize o Terraform para registrá-lo:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

1. **Validação do Output Exportado:**
   Inspecione os outputs retornados pelo Terraform:
   ```bash
   terraform output instance_public_ip
   ```
   *Critério de Aceite:* O comando deve exibir o endereço IPv4 público alocado dinamicamente pela AWS.
2. **Inspeção via AWS CLI:**
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Terraform Module Example'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" --output table
   ```
   *Critério de Aceite:* Uma instância no estado `running` deve ser listada com a tag correspondente.

---

## 🧹 Cleanup

Desprovisione a instância criada pelo módulo:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Instanciação Múltipla:** Chame o módulo `ec2_instance` uma segunda vez no `main.tf` (ex: `module "ec2_backup"`) passando um nome e tipo de instância diferentes. Observe como o Terraform gerencia dois recursos idênticos sem duplicação de lógica.
2. **Validação de Variáveis:** Adicione um bloco `validation` no `variables.tf` do módulo garantindo que `instance_type` seja restrito a `["t2.micro", "t3.micro"]`.
