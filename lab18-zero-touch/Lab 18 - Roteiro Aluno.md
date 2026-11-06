# Lab 18 - Orquestração Zero-Touch (Terraform + Ansible Integrados)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, Ansible Core 2.16+, AWS EC2, Jinja2, Zero-Touch Pipeline  
**Duração Estimada:** 30 minutos  

---

## 🎯 Objetivo do Lab

Construir um pipeline de provisionamento e configuração contínua Zero-Touch (sem intervenção manual humana):
1. Orquestrar o provisionamento de hardware em nuvem via Terraform e gerar dinamicamente artefatos de inventário (`local_file`).
2. Sincronizar a prontidão do daemon SSH da instância virtual através de sondas ativas com `remote-exec`.
3. Disparar a execução automatizada do Ansible Playbook via `local-exec` acoplado a `null_resource`.
4. Obter um serviço de produção completo e configurado em um comando único (`terraform apply`).

---

## 📋 Pré-requisitos & Materiais

- Credenciais da **AWS Academy** em `~/.aws/credentials`.
- Chave privada `labsuser.pem` presente no diretório.
- Terminal posicionado no diretório:
  ```bash
  cd lab18-zero-touch
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Permissões de Segurança da Chave SSH
No terminal do Codespaces:
```bash
chmod 400 labsuser.pem
```

### Passo 2: Análise da Mecânica de Integração no `main.tf`
Abra `main.tf` e examine os blocos de orquestração:
1. **Geração Dinâmica de Inventário:**
   ```hcl
   resource "local_file" "ansible_inventory" {
     content = <<-EOT
     [webservers]
     servidor-zero-touch ansible_host=${aws_instance.web_server.public_ip}

     [webservers:vars]
     ansible_user=ubuntu
     ansible_ssh_private_key_file=${var.private_key_path}
     ansible_ssh_common_args='-o StrictHostKeyChecking=no'
     EOT

     filename = "${path.module}/inventory.ini"
   }
   ```
2. **Sonda de Prontidão e Disparo do Ansible:**
   ```hcl
   resource "null_resource" "trigger_ansible" {
     depends_on = [aws_instance.web_server, local_file.ansible_inventory]

     # Sonda SSH para garantir que o boot finalizou antes de chamar o playbook
     provisioner "remote-exec" {
       inline = ["echo 'SSH Ready!'"]
       connection {
         type        = "ssh"
         user        = "ubuntu"
         private_key = file(var.private_key_path)
         host        = aws_instance.web_server.public_ip
       }
     }

     # Disparo automático do Ansible
     provisioner "local-exec" {
       command = "ansible-playbook -i inventory.ini playbook.yml"
     }
   }
   ```

### Passo 3: Execução Zero-Touch
Inicie o pipeline em comando único:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Acompanhe o fluxo: o Terraform provisiona a VM, gera o `inventory.ini`, aguarda o SSH e dispara o playbook do Ansible configurando o Nginx e renderizando a página final.*

---

## 🧪 Validação & Critérios de Aceite

1. **Validação do Inventário Gerado:**
   ```bash
   cat inventory.ini
   ```
   *Critério de Aceite:* Deve conter o IP público real da máquina provisionada.
2. **Validação do Endpoint Web:**
   Consulte a URL exportada pelo Terraform:
   ```bash
   WEB_URL=$(terraform output -raw web_url)
   curl -s $WEB_URL | grep "Zero-Touch"
   ```
   *Critério de Aceite:* A requisição deve retornar a página HTML com o selo do pipeline Zero-Touch e métricas coletadas pelo Ansible.

---

## 🧹 Cleanup

Desprovisione todos os recursos da nuvem e limpe artefatos gerados:
```bash
terraform destroy -auto-approve
rm -f inventory.ini
cd ..
```

---

## 💡 Desafios Complementares

1. **Dynamic Inventory Plugin:** Em vez de gerar o arquivo estático `inventory.ini` via `local_file`, configure o plugin oficial `amazon.aws.aws_ec2` do Ansible para descobrir os hosts dinamicamente via tags (`tag:Project=ZeroTouch`).
2. **Tratamento de Falha:** Configure a flag `on_failure = continue` no provisionador `local-exec` e avalie o impacto caso o playbook falhe em uma máquina intermediária.
