# Lab 12 - Provisionadores Remotos (Remote Exec Provisioner)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, SSH, Provisioner `remote-exec`, Nginx  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Aprender a executar automações de configuração no sistema operacional de instâncias EC2 via SSH utilizando `remote-exec`:
1. Configurar blocos de conexão remota (`connection`) SSH no Terraform com chaves privadas `.pem`.
2. Compreender a dependência estrita entre Security Groups (portas 22 e 80) e a execução do provisionador para evitar timeouts mascarados.
3. Executar scripts de bootstrap e instalação de pacotes (`yum update`, `nginx`) de forma não-interativa.
4. Testar o serviço web provisionado e analisar trade-offs frente ao `user_data` ou ferramentas de gerenciamento de configuração.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Chave privada `labsuser.pem` (fornecida no laboratório da AWS Academy).
- Terminal posicionado no diretório:
  ```bash
  cd lab12-remoteexec
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Ajuste de Permissões da Chave SSH
No ambiente Linux do Codespaces, chaves privadas exigem permissões restritas (`400`):
```bash
chmod 400 labsuser.pem
```

### Passo 2: Análise da Conexão e do Provisionador no `main.tf`
Abra o arquivo `main.tf` e inspecione os blocos:
```hcl
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/labsuser.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx"
    ]
  }
```
*Atenção de Arquitetura:* O recurso `aws_instance` deve obrigatoriamente associar um Security Group que libere a porta 22 (SSH) na entrada para que o provisionador consiga se conectar. Caso contrário, o Terraform entrará em loop de timeout.

### Passo 3: Execução e Bootstrapping
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*O Terraform aguardará a inicialização do daemon SSH na EC2, estabelecerá a sessão criptografada e transmitirá o log dos comandos do Nginx em tempo real.*

---

## 🧪 Validação & Critérios de Aceite

1. **Validação do Endpoint Web via Curl:**
   Obtenha o IP público da instância e execute um teste HTTP:
   ```bash
   INSTANCE_IP=$(terraform output -raw instance_public_ip)
   curl -I http://$INSTANCE_IP
   ```
   *Critério de Aceite:* O servidor deve responder com status `HTTP/1.1 200 OK` e cabeçalho `Server: nginx`.
2. **Inspeção de Processos via SSH Manual:**
   ```bash
   ssh -i labsuser.pem ec2-user@$INSTANCE_IP "systemctl status nginx"
   ```
   *Critério de Aceite:* O serviço deve estar com status `active (running)`.

---

## 🧹 Cleanup

Desprovisione a infraestrutura:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Substituição por `user_data`:** Avalie o anti-pattern do `remote-exec` (que exige porta 22 aberta na nuvem) e refatore o provisionamento para utilizar `user_data` nativo com `cloud-init`.
2. **Deploy de Aplicação Customizada:** Adicione um provisionador do tipo `file` para transferir um arquivo `index.html` local diretamente para `/usr/share/nginx/html/index.html` antes de iniciar o Nginx.
