# Lab 04 - Gerenciamento de Estado Remoto (S3 Backend & State Locking)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS S3, DynamoDB, Remote State Backend  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a implementar uma arquitetura de colaboração segura com gerenciamento de estado remoto:
1. Provisionar um Bucket S3 criptografado e uma tabela DynamoDB dedicada para controle de concorrência.
2. Habilitar o backend remoto do Terraform e migrar o estado local determinísticamente (`terraform init -migrate-state`).
3. Validar travas de estado atômicas (*State Locking*) para prevenir corrupção concorrente em times de engenharia.
4. Compreender regras de proteção de ciclo de vida (`prevent_destroy`) e procedimentos de reversão de estado.

---

## 📋 Pré-requisitos & Materiais

- Credenciais da **AWS Academy** ativas em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab04-terraform_state
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Parametrização de Identificador Único
Como os nomes de buckets S3 na AWS devem ser globalmente únicos:
1. Abra `main.tf` e substitua o sufixo `-rafael-matsuyama123` por um identificador exclusivo (ex: `-seu-nome-rm`).
2. Abra `backend.tf` e atualize o nome do bucket com o mesmo identificador.

### Passo 2: Provisionar a Infraestrutura de Suporte (Fase Local)
Como o bucket e a tabela DynamoDB ainda não existem, desative temporariamente a declaração de backend remoto para criá-los via estado local:
```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply -auto-approve
```
*O Terraform criará o bucket S3 com versionamento e a tabela DynamoDB com a chave primária `LockID`.*

### Passo 3: Ativar o Backend Remoto e Migrar o Estado
Agora que a infraestrutura física de armazenamento existe:
1. Reative o arquivo de backend:
   ```bash
   mv backend.tf.disabled backend.tf
   ```
2. Inicialize o Terraform para migrar o estado:
   ```bash
   terraform init -migrate-state
   ```
3. Quando solicitado (`Do you want to copy existing state to the new backend?`), digite `yes` e pressione `Enter`.

---

## 🧪 Validação & Critérios de Aceite

1. **Validação do Lock Remoto:**
   Execute um plano:
   ```bash
   terraform plan
   ```
   *Critério de Aceite:* O terminal exibirá mensagens de aquisição de trava (*Acquiring state lock*) e liberação (*Releasing state lock*), confirmando que a tabela DynamoDB está governando a concorrência.
2. **Inspeção do Bucket S3:**
   Consulte os objetos do bucket via AWS CLI:
   ```bash
   aws s3 ls s3://SEU-BUCKET-NAME/
   ```
   *Critério de Aceite:* O arquivo `terraform.tfstate` deve estar presente dentro do bucket.

---

## 🧹 Cleanup

Para destruir a infraestrutura sem erros de trava ou perda de backend:

1. **Desativar Trava de Proteção:**
   No `main.tf`, altere `prevent_destroy = false` (ou comente os blocos `lifecycle`).
2. **Reverter para Backend Local:**
   ```bash
   mv backend.tf backend.tf.disabled
   terraform init -migrate-state
   ```
   *Confirme com `yes` para trazer o estado de volta para o disco local.*
3. **Destruir Recursos:**
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```

---

## 💡 Desafios Complementares

1. **Simulação de Concorrência:** Abra dois terminais simultâneos no Codespaces. No primeiro, execute `terraform apply` sem confirmar. No segundo terminal, execute `terraform plan`. Observe o erro explícito de *Error acquiring the state lock*.
2. **Habilitar KMS:** Configure criptografia server-side no bucket S3 utilizando uma chave gerenciada pelo AWS KMS (`aws_kms_key`).
