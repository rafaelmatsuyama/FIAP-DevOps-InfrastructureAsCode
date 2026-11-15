# Lab 03 - Provisionamento na AWS (Nuvem Real vs. Emulação Local)

**Curso / Disciplina:** MBA em DevOps Engineering — Infrastructure as Code (IaC)  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / LocalStack)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider (`hashicorp/aws ~> 5.0`), EC2, Security Groups, LocalStack  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a provisionar recursos declarativos de computação elástica em nuvem pública (AWS) e compreender a portabilidade de provedores entre nuvem real e emulação local.

**Cenário Corporativo (FinCorp Cloud Onboarding):**  
Na *FinCorp*, desenvolvedores costumam criar máquinas EC2 manualmente via Console Web da AWS (*ClickOps*) para homologação rápida, esquecendo portas administrativas abertas ou instâncias ligadas durante a noite. Sua missão é substituir esse processo manual por um manifesto Terraform auditável com Security Group explícito, outputs estruturados e teardown automatizado.

**Habilidades Conquistadas:**
1. Configurar credenciais temporárias para nuvem real (**AWS Academy**) ou emulação local via **LocalStack**.
2. Declarar instâncias virtuais EC2 (`aws_instance`) e regras de firewall em VPC (`aws_security_group` vinculado via `vpc_security_group_ids`).
3. Expor identificadores e IPs de acesso via blocos `output`.
4. Auditar instâncias ativas via AWS CLI filtrando pelo estado `running` e destruir recursos ao final.

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (Terraform 1.9+ e AWS CLI v2 pré-instalados no DevContainer).
- Credenciais ativas da **AWS Academy** (Opção A) **OU** daemon Docker ativo para contingência com **LocalStack** (Opção B).
- Arquivo fornecido neste laboratório: [`main.tf`](./main.tf).
- Terminal posicionado no diretório do laboratório:
  ```bash
  cd lab03-simple_aws_ec2
  ```

> [!WARNING]
> **Boas Práticas DevSecOps (CIDR `0.0.0.0/0`):**  
> Neste laboratório introdutório, o Security Group `allow_ssh_http` libera SSH (porta `22`) e HTTP (porta `80`) para `0.0.0.0/0` por simplicidade didática em ambientes efêmeros da AWS Academy. **Em ambientes produtivos**, jamais exponha a porta `22` para toda a internet: restrinja o `cidr_blocks` ao IP público da VPN/escritório ou utilize **AWS Systems Manager Session Manager (SSM)** sem abrir porta SSH.

---

## 🚀 Passo a Passo Guiado

### Passo 1: Preparação do Ambiente (Escolha uma opção)

#### 🟢 Opção A: AWS Real (AWS Academy) — *Recomendado*
1. No painel do laboratório da AWS Academy (*Start Lab*), aguarde o indicador ficar verde e copie as credenciais em **AWS Details** -> **AWS CLI**.
2. No Codespaces, abra (ou crie) o arquivo padrão de credenciais:
   ```bash
   mkdir -p ~/.aws && code ~/.aws/credentials
   ```
3. Cole as credenciais exatamente no formato fornecido pela AWS Academy:
   ```ini
   [default]
   aws_access_key_id = SUA_ACCESS_KEY_ID
   aws_secret_access_key = SUA_SECRET_ACCESS_KEY
   aws_session_token = SEU_SESSION_TOKEN
   ```
4. Salve o arquivo (`Ctrl + S`) e valide a sessão:
   ```bash
   aws sts get-caller-identity
   ```

#### 🟡 Opção B: AWS Emulada (LocalStack — Contingência)
Se estiver sem acesso à AWS Academy ou trabalhando offline:
1. Inicie o container do LocalStack em background via Docker:
   ```bash
   docker run -d --name localstack -p 4566:4566 localstack/localstack
   ```
2. Confirme que o container está ativo com `docker ps`.

> [!NOTE]
> **Escopo do LocalStack Community vs. AWS Real:**  
> A edição gratuita (*Community*) do LocalStack emula a API de controle da EC2 para validar o ciclo do Terraform (`init`, `plan`, `apply`, `destroy`) sem gerar custos, porém a máquina virtual não possui conectividade SSH/HTTP real nem sistema operacional inicializado por trás do IP simulado.

---

### Passo 2: Revisar e Ajustar o Provedor no [`main.tf`](./main.tf)

Abra [`main.tf`](./main.tf) e observe a estrutura principal:
- **Se escolheu Opção A (AWS Academy):** Mantenha o bloco `OPTION A` ativo (linhas 10–13) e `OPTION B` comentado.
- **Se escolheu Opção B (LocalStack):** Comente o bloco `provider "aws"` da `OPTION A` e descomente o bloco `OPTION B` (linhas 16–27) apontando para `http://localhost:4566`:
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

Observe também que o recurso `aws_instance.example` utiliza `vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]`, padrão moderno recomendado para VPCs AWS (substituindo a referência legada por nome de EC2-Classic).

---

### Passo 3: Inicialização, Planejamento e Provisionamento

Execute os comandos sequencialmente no terminal:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**Saída Esperada (Exemplo ilustrativo em `us-east-1`):**
```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0a1b2c3d4e5f67890"
instance_public_ip = "54.123.45.67"
```
*(No LocalStack, `instance_public_ip` pode aparecer vazio ou com IP simulado dependendo da versão da imagem.)*

---

## 🧪 Validação & Critérios de Aceite

Valide o recurso provisionado consultando diretamente a API da nuvem e o estado local:

1. **Validação via AWS CLI (AWS Real — filtrando instâncias ativas):**
   ```bash
   aws ec2 describe-instances \
     --filters "Name=instance-state-name,Values=running" \
     --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress,Name:Tags[?Key=='Name'].Value|[0]}" \
     --output table
   ```
   *Critério de Aceite:* A instância com Tag `Terraform Example` deve figurar na tabela com estado `running` e `PublicIP` preenchido.

2. **Validação via AWS CLI (LocalStack):**
   ```bash
   aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
     --filters "Name=instance-state-name,Values=running" \
     --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" \
     --output table
   ```

3. **Auditoria de Outputs e Estado:**
   ```bash
   terraform output
   terraform state list
   ```
   *Critério de Aceite:* `terraform state list` deve listar exatamente `aws_security_group.allow_ssh_http` e `aws_instance.example`.

---

## 🧹 Cleanup (Obrigatório)

Destrua todos os recursos na AWS para evitar consumo desnecessário de créditos da conta Academy:
```bash
terraform destroy -auto-approve
cd ..
```
*Se utilizou o LocalStack, pare e remova o container em seguida:*
```bash
docker stop localstack && docker rm localstack
```

---

## 💡 Desafios Complementares

1. **Alocação de IP Elástico (EIP):** Adicione um recurso `aws_eip` associado à `aws_instance.example` e exponha o IP fixo resultante via bloco `output "elastic_ip"`. (Lembre-se de destruir tudo ao concluir, pois EIPs ociosos geram cobrança na AWS!)
2. **Análise de Impacto em Resize (`t2.micro` para `t3.micro`):** Altere o `instance_type` para `"t3.micro"` no `main.tf` e execute **apenas** `terraform plan`. Observe no plano se a mudança gera modificação *in-place* (`~`) ou recriação destrutiva (`-/+`).
