# Lab 03 - Provisionamento na AWS (Nuvem Real vs. Emulação Local)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / LocalStack)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Security Groups, LocalStack  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a provisionar recursos de computação elástica em nuvem pública ou em ambiente emulado:
1. Configurar credenciais de acesso para nuvem real (AWS Academy) ou emulação via LocalStack.
2. Declarar instâncias virtuais EC2 (`aws_instance`) e grupos de segurança com regras de firewall (`aws_security_group`).
3. Compreender a portabilidade de providers do Terraform entre ambientes de desenvolvimento e produção.
4. Auditar instâncias ativas via AWS CLI e inspecionar o arquivo de estado.

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (Terraform e AWS CLI já configurados no container).
- Credenciais da **AWS Academy** ativas OU daemon do Docker ativo para rodar o LocalStack.
- Terminal posicionado no diretório:
  ```bash
  cd lab03-simple_aws_ec2
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Preparação do Ambiente (Escolha uma opção)

#### 🟢 Opção A: Utilizando a AWS Real (AWS Academy)
Se você já possui as credenciais temporárias da AWS Academy:
1. No console da AWS Academy, copie as credenciais em **AWS Details** -> **AWS CLI**.
2. No Codespaces, abra o arquivo de credenciais:
   ```bash
   mkdir -p ~/.aws && code ~/.aws/credentials
   ```
3. Cole as credenciais estruturadas no formato:
   ```ini
   [default]
   aws_access_key_id = SUA_ACCESS_KEY_ID
   aws_secret_access_key = SUA_SECRET_ACCESS_KEY
   aws_session_token = SEU_SESSION_TOKEN
   ```
4. Salve o arquivo (`Ctrl + S`).

#### 🟡 Opção B: Utilizando a AWS Emulada (LocalStack)
Se estiver sem acesso à AWS Academy ou sem conexão:
1. Inicie o emulador de nuvem em background via Docker:
   ```bash
   docker run -d --name localstack -p 4566:4566 localstack/localstack
   ```
2. Confirme que o LocalStack está ativo com `docker ps`.

### Passo 2: Configurar o Provedor no `main.tf`
Abra o arquivo `main.tf` e valide a configuração do provider:
- **Para Opção A (AWS Real):** Mantenha o provider apontando para `us-east-1`:
  ```hcl
  provider "aws" {
    region = "us-east-1"
  }
  ```
- **Para Opção B (LocalStack):** Ajuste os endpoints para `http://localhost:4566`:
  ```hcl
  provider "aws" {
    region                      = "us-east-1"
    access_key                  = "mock"
    secret_key                  = "mock"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true

    endpoints {
      ec2 = "http://localhost:4566"
    }
  }
  ```

### Passo 3: Inicialização e Execução
Execute sequencialmente no terminal:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

Valide o provisionamento da instância EC2:

1. **Validação via AWS CLI (Nuvem Real):**
   ```bash
   aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" --output table
   ```
   *Critério de Aceite:* Uma instância com Tag `Terraform Example` deve figurar com estado `running`.

2. **Validação via AWS CLI (LocalStack):**
   ```bash
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" --output table
   ```

3. **Inspeção de Estado:**
   ```bash
   terraform show
   ```
   *Critério de Aceite:* O recurso `aws_instance.example` deve exibir seu `public_ip` e atributos de rede alocados.

---

## 🧹 Cleanup

Desprovisione a instância para encerrar custos:
```bash
terraform destroy -auto-approve
cd ..
```
*Se utilizou o LocalStack, encerre o container com `docker stop localstack && docker rm localstack`.*

---

## 💡 Desafios Complementares

1. **Alocação de IP Elástico (EIP):** Adicione um recurso `aws_eip` vinculado à instância EC2 e exponha o endereço IP elástico via bloco `output`.
2. **Atualização de Tipo de Instância:** Altere o `instance_type` de `t2.micro` para `t3.micro`. Execute `terraform plan` e observe se a modificação exige parada/recriação do recurso.
