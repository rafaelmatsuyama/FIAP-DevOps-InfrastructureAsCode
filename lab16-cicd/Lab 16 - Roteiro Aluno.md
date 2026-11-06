# Lab 16 - Pipeline de CI/CD para IaC com GitHub Actions & AWS

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Actions + GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, GitHub Actions, Trivy Security Scanner, AWS EC2, S3 State Sync  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Implementar uma esteira automatizada corporativa de CI/CD para entrega contínua de Infrastructure as Code (GitOps):
1. Configurar um fluxo de trabalho com múltiplos jobs interdependentes no GitHub Actions (`.github/workflows/terraform-pipeline.yml`).
2. Implementar um Quality Gate estrito de DevSecOps: validação de formatação (`fmt`), compilação de sintaxe (`validate`) e análise de vulnerabilidades em HCL (`Trivy`).
3. Gerenciar credenciais de nuvem com segurança utilizando GitHub Actions Secrets.
4. Orquestrar deploy automatizado na AWS e persistência de estado em bucket S3 remoto.
5. Executar ações controladas de desprovisionamento via gatilho manual `workflow_dispatch`.

---

## 📋 Pré-requisitos & Materiais

- Fork pessoal do repositório no GitHub com Actions habilitadas.
- Credenciais da **AWS Academy** cadastradas em **Settings → Secrets and variables → Actions**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN`
  - `AWS_REGION` (`us-east-1`)
- Terminal posicionado no diretório:
  ```bash
  cd lab16-cicd
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Habilitar Actions e Cadastrar Secrets
1. No seu fork no GitHub, acesse a aba **Actions** e confirme a ativação dos workflows.
2. Acesse **Settings → Secrets and variables → Actions** e cadastre as 4 variáveis da AWS Academy.

### Passo 2: Análise da Arquitetura do Workflow
Inspecione o arquivo `.github/workflows/terraform-pipeline.yml` na raiz:
- **Job 1 (Quality Gate & Lint):** Executa `terraform fmt -check`, `terraform validate` e varredura estática com `aquasecurity/trivy-action`.
- **Job 2 (Deploy / Destroy na AWS):** Executado condicionalmente na branch `main` após aprovação do Job 1 (`needs: quality_and_security`). Sincroniza o `terraform.tfstate` em bucket S3 e aplica o plano.

### Passo 3: Disparo por Push (GitOps)
Faça uma alteração cosmética em `lab16-cicd/main.tf` (ex: customizar o banner HTML no `user_data`), faça commit e envie:
```bash
git add lab16-cicd/main.tf
git commit -m "feat(ci): disparo do deploy automatizado via GitHub Actions"
git push origin main
```
*Acesse a aba Actions e acompanhe os dois estágios em tempo real.*

---

## 🧪 Validação & Critérios de Aceite

1. **Auditoria de Execução no GitHub Actions:**
   Abra a execução do workflow e certifique-se de que:
   - O Job `1. Quality Gate & Lint` finalizou verde com 0 violações de segurança no Trivy.
   - O Job `2. Deploy / Destroy na AWS` aplicou as mudanças e exibiu o output `web_url`.
2. **Teste de Conectividade Externa:**
   Copie a URL exposta no log do workflow (ex: `http://54.x.x.x`) e execute:
   ```bash
   curl -I http://IP_DO_WORKFLOW
   ```
   *Critério de Aceite:* Status `HTTP/1.1 200 OK` retornado pelo Nginx.

---

## 🧹 Cleanup

### Método 1: Destruição Automatizada via GitHub Actions (Recomendado)
1. No seu repositório no GitHub, acesse a aba **Actions**.
2. Selecione o workflow **Terraform CI/CD Pipeline (Lab 16)**.
3. Clique em **Run workflow**, selecione a opção **`destroy`** e dispare a execução.

### Método 2: Destruição via Terminal
```bash
cd lab16-cicd
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 cp s3://tfstate-lab16-${ACCOUNT_ID}/terraform.tfstate terraform.tfstate
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Quality Gate Bloqueante:** Edite o workflow e altere o parâmetro do Trivy para `exit-code: 1`. Crie intencionalmente um security group com porta 22 aberta para `0.0.0.0/0` e valide se a esteira bloqueia o deploy automaticamente.
2. **Approval Gate com Environments:** Configure um ambiente `production` no GitHub com proteção de revisores manuais (*Required Reviewers*) antes da etapa de deploy.
