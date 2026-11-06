# Lab 01 - Meu Primeiro Provisionamento (Codespaces + Hello World)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (Linux DevContainer)  
**Linguagem / Stack:** Terraform 1.9+ (Providers `local` & `random`)  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Compreender o ciclo de vida fundamental do Terraform e a abordagem declarativa de Infrastructure as Code (IaC):
1. Inicializar providers declarativos e inspecionar o grafo de dependências (`terraform init`).
2. Gerar planos determinísticos de execução sem alteração de estado (`terraform plan`).
3. Aplicar manifestos e auditar a estrutura do arquivo de estado local (`terraform.tfstate`).
4. Testar a garantia de idempotência e executar a destruição controlada do ambiente (`terraform destroy`).

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (o ambiente já carrega o Terraform pré-instalado via DevContainer).
- Terminal de execução posicionado na pasta do laboratório:
  ```bash
  cd lab01-hello_world
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Inspeção do Manifesto Declarativo
Abra o arquivo `main.tf` presente na pasta `lab01-hello_world` e analise seus blocos de configuração:
- **`terraform`:** Declara as versões mínimas exigidas da ferramenta e dos providers (`local` e `random`).
- **`random_id.unique_suffix`:** Gera um identificador randômico de 4 bytes (hexadecimal) para simular identificadores únicos de infraestrutura.
- **`local_file.hello_fiap`:** Cria um arquivo em disco interpolando a saída do gerador randômico.

### Passo 2: Inicialização do Workspace
No terminal, inicialize o diretório de trabalho do Terraform:
```bash
terraform init
```
*O Terraform lê o `main.tf`, baixa os plugins dos provedores oficiais a partir do Terraform Registry e cria a pasta oculta `.terraform/`.*

### Passo 3: Planejamento Determinístico
Gere o plano de execução para visualizar quais recursos serão criados:
```bash
terraform plan
```
*Observe a saída no terminal: o Terraform exibe `Plan: 2 to add, 0 to change, 0 to destroy` com o símbolo verde `+`, indicando ações atômicas.*

### Passo 4: Aplicação das Mudanças
Execute a criação dos recursos em disco:
```bash
terraform apply
```
*Quando o Terraform solicitar confirmação (`Enter a value:`), digite `yes` e pressione `Enter`.*

---

## 🧪 Validação & Critérios de Aceite

Execute os seguintes comandos para validar a entrega com sucesso:

1. **Validação do Arquivo Criado:**
   Confirme que o arquivo `hello_world.txt` foi gerado com o identificador único:
   ```bash
   cat hello_world.txt
   ```
2. **Auditoria do Estado (`terraform.tfstate`):**
   Inspecione o arquivo de estado gerado pelo motor do Terraform:
   ```bash
   terraform show
   ```
   *Note que o Terraform armazena os metadados exatos dos recursos criados em um JSON estruturado.*
3. **Teste de Idempotência:**
   Execute o `apply` novamente sem alterar o código:
   ```bash
   terraform apply -auto-approve
   ```
   *Critério de Aceite:* A saída deve indicar `Apply complete! Resources: 0 added, 0 changed, 0 destroyed`, provando que o estado desejado já reflete o estado real.

---

## 🧹 Cleanup

Para manter o ambiente higienizado e concluir o ciclo de vida:
```bash
terraform destroy -auto-approve
cd ..
```
*Confirme que o arquivo `hello_world.txt` foi removido automaticamente do diretório.*

---

## 💡 Desafios Complementares

1. **Alteração de Byte Length:** Altere o parâmetro `byte_length = 4` do recurso `random_id` para `byte_length = 8`. Execute `terraform plan` e observe como o Terraform trata a alteração (recriação com substituição indicada por `-/+`).
2. **Adição de Novo Arquivo:** Crie um segundo recurso `local_file` apontando para `status.json` com um payload JSON mockado e aplique as alterações.
