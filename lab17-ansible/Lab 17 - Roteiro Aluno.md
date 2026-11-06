# Lab 17 - Automação Multi-Host com Ansible & Templates Jinja2

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, Ansible Core 2.16+, EC2, Jinja2 Templates, Nginx  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Implementar o modelo corporativo de automação híbrida (IaC + Configuration Management):
1. Estabelecer a divisão de fronteiras: Terraform provisiona a infraestrutura de nuvem e Ansible governa o sistema operacional.
2. Estruturar inventários estáticos multi-host e testar conectividade paralela via módulo `ping`.
3. Coletar fatos de hardware (`gather_facts`) e renderizar páginas dinâmicas com templates Jinja2 (`.j2`).
4. Validar e certificar a garantia fundamental de **Idempotência** (`changed=0` em execuções subsequentes).

---

## 📋 Pré-requisitos & Materiais

- Credenciais da **AWS Academy** em `~/.aws/credentials`.
- Chave privada `labsuser.pem` disponível para autenticação SSH.
- Terminal posicionado no diretório:
  ```bash
  cd lab17-ansible
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Provisionar a Infraestrutura com Terraform
No terminal:
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```
*Anote os IPs públicos exibidos no output `public_ips`.*

### Passo 2: Configurar o Inventário do Ansible
1. Navegue para o diretório de automação:
   ```bash
   cd ../ansible
   ```
2. Assegure as permissões restritas da chave SSH:
   ```bash
   chmod 400 labsuser.pem
   ```
3. Abra `inventory.ini` e atualize os endereços IP capturados no Passo 1:
   ```ini
   [webservers]
   servidor-01 ansible_host=IP_DO_SERVIDOR_01
   servidor-02 ansible_host=IP_DO_SERVIDOR_02

   [webservers:vars]
   ansible_user=ubuntu
   ansible_ssh_private_key_file=./labsuser.pem
   ansible_ssh_common_args='-o StrictHostKeyChecking=no'
   ```

### Passo 3: Teste de Conectividade Paralela
Valide a comunicação SSH com toda a frota:
```bash
ansible webservers -i inventory.ini -m ping
```
*Critério: Retorno `"ping": "pong"` em verde para ambos os hosts.*

### Passo 4: Execução do Playbook com Templates Jinja2
Inspecione `playbook.yml` e o template `templates/index.html.j2`, em seguida aplique a configuração:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Passo 5: Teste de Idempotência
Re-execute o mesmo comando do playbook imediatamente:
```bash
ansible-playbook -i inventory.ini playbook.yml
```
*Observe a recapitulação: `ok=5 changed=0 unreachable=0 failed=0`. O Ansible detecta que o estado real já atende a declaração e não executa mudanças desnecessárias.*

---

## 🧪 Validação & Critérios de Aceite

1. **Validação HTTP nos Dois Nós:**
   ```bash
   curl -s http://IP_DO_SERVIDOR_01 | grep "Hostname:"
   curl -s http://IP_DO_SERVIDOR_02 | grep "Hostname:"
   ```
   *Critério de Aceite:* Cada servidor deve exibir seu próprio hostname e endereço IP privado renderizados dinamicamente pelo Jinja2.

---

## 🧹 Cleanup

Desprovisione a infraestrutura para economizar créditos:
```bash
cd ../terraform
terraform destroy -auto-approve
cd ../..
```

---

## 💡 Desafios Complementares

1. **Handler de Reinicialização de Serviço:** Adicione um `handler` no Ansible para reiniciar o serviço Nginx exclusivamente quando o arquivo de template `index.html.j2` for modificado.
2. **Variáveis de Grupo:** Adicione uma variável personalizada `site_title = "Ambiente de Produção FIAP"` em `[webservers:vars]` e exiba-a no template HTML.
