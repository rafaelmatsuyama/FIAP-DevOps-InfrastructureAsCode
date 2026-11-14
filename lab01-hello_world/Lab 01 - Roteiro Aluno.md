# Lab 01 - Meu Primeiro Provisionamento (Codespaces + Hello World)

**Curso / Disciplina:** MBA em DevOps Engineering — Infrastructure as Code (IaC)  
**Plataforma / Ambiente:** GitHub Codespaces (Linux DevContainer)  
**Linguagem / Stack:** Terraform 1.9+ (Providers `local` & `random`)  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a dominar o ciclo de vida declarativo do Terraform e a governança de estado local antes de provisionar recursos pagos em nuvem pública.

**Cenário Corporativo (FinCorp Platform Engineering):**  
A equipe de engenharia de plataforma da *FinCorp* precisa eliminar scripts imperativos frágeis que geram arquivos de configuração manualmente nos servidores, causando inconsistências entre ambientes. Sua missão neste primeiro exercício é validar o motor declarativo do Terraform em modo sandbox (custo zero), gerando um identificador único criptográfico e um artefato de controle determinístico em disco.

**Habilidades Conquistadas:**
1. Inicializar providers declarativos e gerar o arquivo de lock de dependências (`terraform init`).
2. Analisar planos determinísticos de execução antes de qualquer alteração física (`terraform plan`).
3. Aplicar manifestos e auditar o arquivo de estado gerado (`terraform.tfstate`).
4. Comprovar a garantia de **Idempotência** e executar o descomissionamento controlado (`terraform destroy`).

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (o DevContainer já carrega o Terraform 1.9+ pré-instalado).
- Arquivo fornecido neste laboratório: [`main.tf`](./main.tf).
- Terminal de execução posicionado na pasta do laboratório:
  ```bash
  cd lab01-hello_world
  ```

> [!TIP]
> **🚀 Ambiente Zero-Friction (Custo Zero):**  
> Este laboratório utiliza exclusivamente os providers locais `hashicorp/local` e `hashicorp/random`. Não são necessárias credenciais da AWS Academy nesta etapa.

---

## 🚀 Passo a Passo Guiado

### Passo 1: Inspeção do Manifesto Declarativo
Abra o arquivo [`main.tf`](./main.tf) presente na pasta `lab01-hello_world` e analise seus blocos de configuração:
- **`terraform`:** Declara as versões mínimas exigidas do motor (`>= 1.9.0`) e dos providers (`local` e `random`).
- **`random_id.unique_suffix`:** Gera um identificador randômico de 4 bytes (8 caracteres hexadecimais) para simular sufixos únicos de infraestrutura.
- **`local_file.hello_fiap`:** Cria um arquivo em disco interpolando `${random_id.unique_suffix.hex}`, estabelecendo uma dependência implícita no grafo DAG.

### Passo 2: Inicialização do Workspace
No terminal, inicialize o diretório de trabalho do Terraform:
```bash
terraform init
```

> **Saída Esperada:**
> ```text
> Initializing the backend...
> Initializing provider plugins...
> - Finding hashicorp/local versions matching "~> 2.5.1"...
> - Finding hashicorp/random versions matching "~> 3.6.0"...
> - Installing hashicorp/local v2.5.3...
> - Installing hashicorp/random v3.6.3...
> Terraform has created a lock file .terraform.lock.hcl to record the provider
> selections it made above.
>
> Terraform has been successfully initialized!
> ```

### Passo 3: Planejamento Determinístico
Gere o plano de execução para visualizar quais recursos serão criados antes de alterar o ambiente:
```bash
terraform plan
```

> **Saída Esperada (Trecho Relevante):**
> ```text
> Terraform will perform the following actions:
>
>   # local_file.hello_fiap will be created
>   + resource "local_file" "hello_fiap" {
>       + content  = (known after apply)
>       + filename = "./hello_world.txt"
>       + id       = (known after apply)
>     }
>
>   # random_id.unique_suffix will be created
>   + resource "random_id" "unique_suffix" {
>       + byte_length = 4
>       + hex         = (known after apply)
>       + id          = (known after apply)
>     }
>
> Plan: 2 to add, 0 to change, 0 to destroy.
> ```

### Passo 4: Aplicação das Mudanças
Execute a criação dos recursos em disco:
```bash
terraform apply
```
*Quando o Terraform solicitar confirmação (`Enter a value:`), digite `yes` e pressione `Enter`.*

> **Saída Esperada:**
> ```text
> random_id.unique_suffix: Creating...
> random_id.unique_suffix: Creation complete after 0s [id=...]
> local_file.hello_fiap: Creating...
> local_file.hello_fiap: Creation complete after 0s [id=...]
>
> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
> ```

> [!WARNING]
> **Governança do Estado (`terraform.tfstate`):**  
> Após o `apply`, o Terraform cria o arquivo `terraform.tfstate` em disco. Em projetos reais de nuvem, **nunca** versione arquivos `.tfstate` no Git (nosso `.gitignore` bloqueia automaticamente), pois eles armazenam metadados completos e eventuais segredos em texto claro.

---

## 🧪 Validação & Critérios de Aceite

Execute os seguintes comandos para validar a entrega com sucesso:

1. **Validação do Arquivo Criado:**
   Confirme que o arquivo `hello_world.txt` foi gerado com o identificador único:
   ```bash
   cat hello_world.txt
   ```
   > **Saída Esperada:**
   > ```text
   > Hello, FIAP DevOps Engineer! Unique infrastructure identifier: 68afa96a
   > ```
   *(O sufixo hexadecimal de 8 caracteres será gerado aleatoriamente na sua execução).*

2. **Auditoria do Estado (`terraform.tfstate`):**
   Inspecione o arquivo de estado gerenciado pelo motor do Terraform:
   ```bash
   terraform show
   ```
   *Critério de Aceite:* Os recursos `local_file.hello_fiap` e `random_id.unique_suffix` devem exibir todos os atributos resolvidos, incluindo hashes SHA256/MD5 e o valor `hex` atribuído.

3. **Teste de Idempotência:**
   Execute o `apply` novamente sem alterar o código:
   ```bash
   terraform apply -auto-approve
   ```
   > **Saída Esperada:**
   > ```text
   > No changes. Your infrastructure matches the configuration.
   >
   > Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
   > ```
   *Critério de Aceite:* Zero alterações aplicadas, provando que o estado desejado já converge com o estado real.

---

## 🧹 Cleanup

Para manter o ambiente higienizado e concluir o ciclo de vida:
```bash
terraform destroy -auto-approve
cd ..
```

> **Saída Esperada:**
> ```text
> Plan: 0 to add, 0 to change, 2 to destroy.
> ...
> Destroy complete! Resources: 2 destroyed.
> ```
*Confirme com `ls` que o arquivo `hello_world.txt` foi removido automaticamente do diretório.*

---

## 💡 Desafios Complementares

1. **Alteração de Byte Length (`ForceNew` / `-/+`):** Altere o parâmetro `byte_length = 4` do recurso `random_id.unique_suffix` para `byte_length = 8`. Execute `terraform plan` e observe como o Terraform propaga a recriação em cascata (`-/+ destroy and then create replacement`) para o arquivo dependente.
2. **Adição de Novo Arquivo Estruturado (`jsonencode`):** Crie um segundo recurso `local_file` apontando para `status.json` utilizando a função nativa `jsonencode()` com um payload JSON mockado e aplique apenas esse delta.
