# Lab 02 - Provisionamento Local (Terraform + Docker no Codespaces)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (Linux DevContainer com Docker socket)  
**Linguagem / Stack:** Terraform 1.9+, Docker Provider (`kreuzwerker/docker`), Nginx  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a gerenciar recursos reais de infraestrutura de computação containerizada via código declarativo:
1. Declarar provedores externos mantidos pela comunidade via Terraform Registry (`kreuzwerker/docker`).
2. Gerenciar o ciclo de vida completo de imagens e containers Docker (`docker_image` e `docker_container`).
3. Analisar atributos de estado de alta complexidade (mapeamento de portas, IDs de runtime, bridge networks).
4. Praticar testes de conectividade em portas encaminhadas no GitHub Codespaces.

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (com Docker daemon e Terraform ativos via DevContainer).
- Terminal posicionado no diretório do laboratório:
  ```bash
  cd lab02-docker_basics
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Manifesto `main.tf`
Abra o arquivo `main.tf` e observe a declaração dos recursos:
- **`required_providers`:** Especifica a origem `kreuzwerker/docker` no Terraform Registry.
- **`resource "docker_image" "nginx"`:** Instrução declarativa para baixar a imagem `nginx:latest` do Docker Hub caso ela não esteja em cache local.
- **`resource "docker_container" "nginx_web"`:** Define o provisionamento do container referenciando o ID da imagem declarada acima (`docker_image.nginx.image_id`), expondo a porta interna 80 na porta externa 8080.

### Passo 2: Inicialização do Provedor
Execute no terminal:
```bash
terraform init
```
*O Terraform baixará o binário do provedor `kreuzwerker/docker` e criará o arquivo de trava de dependência.*

### Passo 3: Geração do Plano de Execução
Gere o plano determinístico:
```bash
terraform plan
```
*Observe que o Terraform exibirá a intenção de adicionar 2 recursos (`Plan: 2 to add, 0 to change, 0 to destroy`).*

### Passo 4: Aplicação das Mudanças
Inicie a criação da imagem e a execução do container:
```bash
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

Valide o provisionamento através das seguintes verificações:

1. **Inspeção via Docker CLI:**
   Consulte os containers ativos no host:
   ```bash
   docker ps --filter "name=fiap-web-server"
   ```
   *Critério de Aceite:* O container `fiap-web-server` deve figurar com status `Up` e redirecionamento de porta `0.0.0.0:8080->80/tcp`.
2. **Teste de Conectividade HTTP:**
   Faça uma requisição direta ao endpoint local no terminal:
   ```bash
   curl -s http://localhost:8080 | grep "Welcome to nginx"
   ```
   *Critério de Aceite:* O comando deve retornar o trecho HTML oficial contendo `<title>Welcome to nginx!</title>`.
3. **Inspeção de Estado Avançado:**
   Exiba os metadados gravados no state:
   ```bash
   terraform show
   ```
   *Note a presença de atributos dinâmicos como `network_data`, `ip_address` e `gateway`.*

---

## 🧹 Cleanup

Para encerrar o container, remover a imagem e liberar recursos:
```bash
terraform destroy -auto-approve
cd ..
```
*Valide com `docker ps` que o container foi encerrado com sucesso.*

---

## 💡 Desafios Complementares

1. **Injeção de Página Customizada:** Crie um volume local montando um arquivo `index.html` personalizado dentro de `/usr/share/nginx/html/` via bloco `volumes` no `docker_container`.
2. **Variáveis Parametrizadas:** Crie um arquivo `variables.tf` para permitir que o usuário defina a porta externa (`8080`) como variável de entrada.
