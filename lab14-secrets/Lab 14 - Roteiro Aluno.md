# Lab 14 - Integração com AWS Secrets Manager (Gerenciamento de Segredos)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, Secrets Manager, EC2, `user_data`, `jsondecode()`  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Implementar os princípios de DevSecOps para gestão centralizada e injeção segura de credenciais sensíveis em tempo de execução:
1. Eliminar o anti-pattern de credenciais e chaves criptográficas expostas em código HCL ou versionadas no Git.
2. Criar e gerenciar segredos estruturados no AWS Secrets Manager via console ou CLI.
3. Consultar versões ativas de segredos dinamicamente via data source `aws_secretsmanager_secret_version`.
4. Processar payloads JSON nativamente utilizando a função `jsondecode()`.
5. Injetar credenciais com segurança no bootstrap (`user_data`) de instâncias EC2.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab14-secrets
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Cadastro do Segredo no AWS Secrets Manager
Via AWS CLI no terminal do Codespaces, crie o segredo estruturado:
```bash
aws secretsmanager create-secret \
  --name "database_credentials2" \
  --description "Credenciais do banco para a aula de IaC" \
  --secret-string '{"username":"admin","password":"S3cureP@ssw0rd!2026"}' \
  --region us-east-1
```

### Passo 2: Análise da Injeção Dinâmica no `main.tf`
Abra `main.tf` e examine a captura e decodificação do segredo:
```hcl
data "aws_secretsmanager_secret_version" "example" {
  secret_id = "database_credentials2"
}

resource "aws_instance" "secrets_instance" {
  ami           = "ami-00ca32bbc84273381"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Username: ${jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["username"]}" > /tmp/secrets.txt
              echo "Password: ${jsondecode(data.aws_secretsmanager_secret_version.example.secret_string)["password"]}" >> /tmp/secrets.txt
              EOF

  tags = {
    Name = "Instance with Secrets"
  }
}
```

### Passo 3: Execução do Ciclo de Vida
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Observe que o Terraform omite os valores confidenciais marcados como sensíveis nos logs do plano.*

---

## 🧪 Validação & Critérios de Aceite

1. **Inspeção via AWS CLI:**
   Capture o ID da instância provisionada:
   ```bash
   INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values='Instance with Secrets'" --query "Reservations[*].Instances[*].InstanceId" --output text)
   echo "Instância: $INSTANCE_ID"
   ```
2. **Auditoria de `user_data` Codificado:**
   Consulte os metadados de inicialização enviados para a instância:
   ```bash
   aws ec2 describe-instance-attribute --instance-id $INSTANCE_ID --attribute userData --query "UserData.Value" --output text | base64 -d
   ```
   *Critério de Aceite:* O script decodificado deve conter o usuário e senha injetados a partir do Secrets Manager.

---

## 🧹 Cleanup

1. Destruir a instância computacional:
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```
2. Excluir o segredo do Secrets Manager com deleção forçada:
   ```bash
   aws secretsmanager delete-secret --secret-id "database_credentials2" --force-delete-without-recovery --region us-east-1
   ```

---

## 💡 Desafios Complementares

1. **IAM Role & Instance Profile:** Em vez de gravar credenciais no `user_data` (que pode ser lido no console), configure uma IAM Role com política de leitura do Secrets Manager associada à instância para consulta direta via SDK da aplicação.
2. **Rotação Automática:** Explore as configurações de rotação automática do Secrets Manager utilizando uma função AWS Lambda.
