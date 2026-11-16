# Lab 04 - Gerenciamento de Estado Remoto (S3 Backend & State Locking)

**Curso / Disciplina:** MBA em DevOps Engineering — Infrastructure as Code (IaC)  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS S3, DynamoDB, Remote State Backend  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a implementar uma arquitetura de colaboração segura com gerenciamento de estado remoto na AWS.

**Cenário Corporativo (FinCorp Platform Engineering):**  
Na *FinCorp*, dois engenheiros executaram `terraform apply` simultaneamente a partir de seus próprios notebooks usando o `terraform.tfstate` local desatualizado, sobrescrevendo alterações críticas de produção e corrompendo o estado compartilhado. Sua missão é centralizar o arquivo de estado em um bucket S3 versionado com travas distribuídas via DynamoDB, garantindo concorrência atômica e auditoria.

**Habilidades Conquistadas:**
1. Provisionar um bucket S3 versionado (`aws_s3_bucket` + `aws_s3_bucket_versioning`) e uma tabela DynamoDB dedicada (`LockID`).
2. Resolver o padrão *Chicken-and-Egg* de bootstrap e migrar estado local para remoto (`terraform init -migrate-state`).
3. Validar travas de estado atômicas (*State Locking*) evitando corrupção concorrente.
4. Gerenciar proteções de ciclo de vida (`prevent_destroy`) e executar teardown seguro de bucket versionado.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials` (valide antes com `aws sts get-caller-identity`).
- Arquivos fornecidos neste laboratório: [`main.tf`](./main.tf) e [`backend.tf`](./backend.tf).
- Terminal posicionado no diretório do laboratório:
  ```bash
  cd lab04-terraform_state
  ```

> [!NOTE]
> **Por que `backend.tf` usa valores fixos e não `var.bucket_name`?**  
> O bloco `terraform { backend "s3" { ... } }` é avaliado pelo Terraform **antes** do carregamento de variáveis e recursos. Por restrição arquitetural do HCL, blocos `backend` não aceitam referências (`var.` ou interpolações); em pipelines reais utiliza-se `-backend-config` ou um wrapper como Terragrunt.

---

## 🚀 Passo a Passo Guiado

### Passo 1: Parametrização de Identificador Único Global
Nomes de buckets S3 são únicos em toda a AWS globalmente:
1. Abra [`main.tf`](./main.tf) e substitua `-your-initials` em `terraform-state-fiap-your-initials` por um sufixo exclusivo seu (ex.: `terraform-state-fiap-maria-silva-2026`, usando apenas letras minúsculas, números e hífens).
2. Abra [`backend.tf`](./backend.tf) e informe **exatamente o mesmo nome de bucket** no atributo `bucket`.

### Passo 2: Provisionar a Infraestrutura de Suporte (Fase Local — *Bootstrap*)
Como o bucket S3 e a tabela DynamoDB ainda não existem na sua conta AWS, desative temporariamente o backend remoto para criá-los utilizando o estado local:
```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply -auto-approve
```
**Saída Esperada:**
```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

dynamodb_lock_table = "terraform-locks"
state_bucket_name = "terraform-state-fiap-maria-silva-2026"
```

### Passo 3: Ativar o Backend Remoto e Migrar o Estado
Agora que o bucket S3 e a tabela DynamoDB existem fisicamente na AWS:
1. Reative o arquivo de configuração de backend:
   ```bash
   mv backend.tf.disabled backend.tf
   ```
2. Execute a inicialização com migração de estado:
   ```bash
   terraform init -migrate-state
   ```
3. Quando o Terraform perguntar `Do you want to copy existing state to the new backend?`, digite `yes` e pressione `Enter`.

**Saída Esperada (Trecho):**
```text
Initializing the backend...
Acquiring state lock. This may take a few moments...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Releasing state lock. This may take a few moments...
```

> [!TIP]
> **Nota de Evolução (Terraform 1.10+):**  
> Este lab utiliza `dynamodb_table` (padrão em ambientes Terraform `<= 1.9` e corporativos consolidados). A partir do Terraform `1.10+`, o backend `s3` também suporta trava nativa em S3 via `use_lockfile = true`, dispensando DynamoDB em novos projetos.

---

## 🧪 Validação & Critérios de Aceite

1. **Validação do State Locking (DynamoDB):**
   ```bash
   terraform plan
   ```
   *Critério de Aceite:* O terminal exibe `Acquiring state lock` antes da leitura e `Releasing state lock` ao concluir, indicando `No changes. Your infrastructure matches the configuration.`

2. **Inspeção do Bucket S3 via AWS CLI:**
   ```bash
   aws s3 ls s3://SEU-BUCKET-NAME/
   ```
   *Critério de Aceite:* O objeto `terraform.tfstate` aparece listado no bucket remoto. (Remova o arquivo local `terraform.tfstate.backup` se desejar confirmar que a leitura vem exclusivamente do S3.)

---

## 🧹 Cleanup (Ordem Obrigatória)

Por causa do bloqueio `prevent_destroy = true` e do versionamento S3 ativo, siga esta ordem exata para não travar a exclusão:

1. **Liberar Proteção de Ciclo de Vida no [`main.tf`](./main.tf):**
   Altere `prevent_destroy = false` nos dois blocos `lifecycle` (`aws_s3_bucket` e `aws_dynamodb_table`) e aplique ou prepare a remoção.
2. **Reverter o Estado para o Disco Local:**
   ```bash
   mv backend.tf backend.tf.disabled
   terraform init -migrate-state
   ```
   *Confirme com `yes` para trazer o estado de volta do S3 para o arquivo local.*
3. **Esvaziar Versões do Bucket S3 (se necessário):**
   Como o versionamento do S3 guarda revisões antigas do `terraform.tfstate`, se o `terraform destroy` retornar `BucketNotEmpty`, remova todas as versões/marcadores do bucket (pelo Console AWS -> **Empty bucket** ou AWS CLI) antes de repetir o `destroy`.
4. **Destruir os Recursos:**
   ```bash
   terraform destroy -auto-approve
   cd ..
   ```

> [!WARNING]
> **Atenção ao Timer da AWS Academy:**  
> Realize o cleanup antes que o cronômetro de sessão da AWS Academy expire; caso contrário, os recursos remanescentes serão encerrados apenas quando a sandbox for reciclada.

---

## 💡 Desafios Complementares

1. **Simulação de Concorrência:** Abra dois terminais no Codespaces. No Terminal 1, execute `terraform apply` e **não responda** ao prompt `Enter a value:`. No Terminal 2, execute `terraform plan`. Observe o erro `Error acquiring the state lock` indicando o `Lock Info` (ID, usuário e timestamp). (Cancele no Terminal 1 com `Ctrl + C` ou `no` para liberar a trava.)
2. **Criptografia com AWS KMS:** Adicione uma chave gerenciada `aws_kms_key` e um recurso `aws_s3_bucket_server_side_encryption_configuration` usando `sse_algorithm = "aws:kms"`.
