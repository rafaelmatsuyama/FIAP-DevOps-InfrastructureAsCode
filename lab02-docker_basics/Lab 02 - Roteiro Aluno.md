# Lab 02 - Provisionamento Local (Terraform + Docker no Codespaces)

**Curso / Disciplina:** MBA em DevOps Engineering — Infrastructure as Code (IaC)  
**Plataforma / Ambiente:** GitHub Codespaces (Linux DevContainer com Docker socket)  
**Linguagem / Stack:** Terraform 1.9+, Docker Provider (`kreuzwerker/docker`), Nginx  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Capacitar o aluno a gerenciar recursos reais de infraestrutura de computação containerizada via código declarativo antes de provisionar workloads pagos em nuvem pública.

**Cenário Corporativo (FinCorp Developer Experience):**  
Desenvolvedores e engenheiros de QA da *FinCorp* perdem horas configurando servidores web localmente com comandos `docker run` manuais e parâmetros divergentes entre máquinas (*"na minha máquina funciona"*). Sua missão é padronizar o provisionamento de containers web Nginx via Terraform, garantindo reprodutibilidade, rastreamento de estado e teardown limpo.

**Habilidades Conquistadas:**
1. Declarar provedores externos mantidos pela comunidade via Terraform Registry (`kreuzwerker/docker`).
2. Gerenciar o ciclo de vida completo de imagens e containers Docker (`docker_image` e `docker_container`).
3. Analisar atributos de estado de alta complexidade (mapeamento de portas, IDs de runtime, bridge networks) e expor `outputs`.
4. Validar encaminhamento de portas (`Port Forwarding`) e conectividade HTTP no GitHub Codespaces.

---

## 📋 Pré-requisitos & Materiais

- Repositório aberto no **GitHub Codespaces** (com Docker daemon e Terraform 1.9+ ativos via DevContainer).
- Arquivo fornecido neste laboratório: [`main.tf`](./main.tf).
- Terminal posicionado no diretório do laboratório:
  ```bash
  cd lab02-docker_basics
  ```

> [!TIP]
> **🚀 Ambiente Zero-Friction (Custo Zero):**  
> Este laboratório utiliza o socket Docker integrado ao Codespaces (`docker-outside-of-docker`). Não são necessárias credenciais da AWS Academy nesta etapa.

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Manifesto `main.tf`
Abra o arquivo [`main.tf`](./main.tf) e observe a declaração dos recursos e outputs:
```hcl
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx_web" {
  image = docker_image.nginx.image_id
  name  = "fiap-web-server"

  ports {
    internal = 80
    external = 8080
  }
}
```
- **`required_providers`:** Conecta ao provider comunitário `kreuzwerker/docker` (`~> 3.0.1`) no Terraform Registry.
- **`docker_image.nginx`:** Baixa a imagem `nginx:latest` caso não esteja em cache. Com `keep_locally = false`, o `terraform destroy` também remove a imagem local.
- **`docker_container.nginx_web`:** Referencia `docker_image.nginx.image_id` (dependência implícita no DAG) e publica a porta interna `80` na porta externa `8080`.
- **`output "web_url"` e `output "container_id"`:** Expõem o endpoint HTTP e o ID de runtime do container após o provisionamento.

### Passo 2: Inicialização do Provedor
Execute no terminal:
```bash
terraform init
```

> **Saída Esperada:**
> ```text
> Initializing the backend...
> Initializing provider plugins...
> - Finding kreuzwerker/docker versions matching "~> 3.0.1"...
> - Installing kreuzwerker/docker v3.0.2...
> - Installed kreuzwerker/docker v3.0.2 (self-signed, key ID BD080C4571C6104C)
>
> Terraform has been successfully initialized!
> ```

### Passo 3: Geração do Plano de Execução
Gere o plano determinístico:
```bash
terraform plan
```

> **Saída Esperada (Resumo):**
> ```text
> Plan: 2 to add, 0 to change, 0 to destroy.
>
> Changes to Outputs:
>   + container_id = (known after apply)
>   + web_url      = "http://localhost:8080"
> ```

### Passo 4: Aplicação das Mudanças
Inicie o pull da imagem e a criação do container:
```bash
terraform apply -auto-approve
```

> **Saída Esperada:**
> ```text
> docker_image.nginx: Creating...
> docker_image.nginx: Creation complete after ...
> docker_container.nginx_web: Creating...
> docker_container.nginx_web: Creation complete after ...
>
> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
>
> Outputs:
> container_id = "..."
> web_url = "http://localhost:8080"
> ```

---

## 🧪 Validação & Critérios de Aceite

Valide o provisionamento através das seguintes verificações:

1. **Inspeção via Docker CLI:**
   Consulte os containers ativos no host:
   ```bash
   docker ps --filter "name=fiap-web-server"
   ```
   > **Saída Esperada:**
   > ```text
   > CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                  NAMES
   > a1b2c3d4e5f6   <image_id>     "/docker-entrypoint.…"   5 seconds ago   Up 4 seconds   0.0.0.0:8080->80/tcp   fiap-web-server
   > ```

2. **Teste de Conectividade HTTP:**
   Faça uma requisição direta ao endpoint local no terminal:
   ```bash
   curl -s http://localhost:8080 | grep "Welcome to nginx"
   ```
   > **Saída Esperada:**
   > ```text
   > <title>Welcome to nginx!</title>
   > <h1>Welcome to nginx!</h1>
   > ```

   > [!TIP]
   > **🌐 Visualizando no Navegador (Codespaces Ports):**  
   > No GitHub Codespaces, abra a aba **Ports** (ao lado de *Terminal*), localize a porta **8080** e clique no ícone de globo (**Open in Browser**) para visualizar a página do Nginx renderizada pela URL encaminhada pelo Codespaces.

3. **Inspeção de Outputs e Estado Avançado:**
   ```bash
   terraform output
   terraform show
   ```
   *Critério de Aceite:* `terraform output` exibe `container_id` e `web_url`; `terraform show` lista os metadados dinâmicos do container (`network_data`, `ip_address`, `gateway` e `ports`).

---

## 🧹 Cleanup

Para encerrar o container, remover a imagem do cache local e liberar a porta `8080`:
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
*Confirme com `docker ps` que o container `fiap-web-server` foi encerrado (e com `docker images` que `nginx:latest` foi removida devido a `keep_locally = false`).*

---

## 💡 Desafios Complementares

1. **Injeção de Página Customizada (`volumes`):** Crie um arquivo `index.html` personalizado na pasta do lab e monte-o dentro de `/usr/share/nginx/html/index.html` usando o bloco `volumes` no `docker_container` (dica: utilize `host_path = abspath("${path.module}/index.html")`, pois o daemon Docker exige caminho absoluto).
2. **Variáveis Parametrizadas (`variables.tf`):** Crie um arquivo `variables.tf` declarando a variável `external_port` (tipo `number`, default `8080`) com validação de intervalo válido (`1024` a `65535`) e conecte-a ao bloco `ports` no `main.tf`.
