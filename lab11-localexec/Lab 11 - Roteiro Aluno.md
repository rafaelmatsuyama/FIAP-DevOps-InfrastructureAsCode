# Lab 11 - Provisionadores Locais (Local Exec Provisioner)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Provisioner `local-exec`  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Compreender a atuação e as fronteiras de responsabilidade dos provisionadores locais (`local-exec`) no Terraform:
1. Analisar o ciclo de execução de lifecycle hooks pós-criação de recursos.
2. Capturar atributos dinâmicos da infraestrutura em nuvem (como IPs e IDs) e persisti-los localmente via shell.
3. Compreender as desvantagens dos provisionadores como anti-pattern de portabilidade e quando utilizá-los legitimamente.
4. Auditar a geração de artefatos de inventário na máquina controladora.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab11-localexec
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Bloco `provisioner "local-exec"` no `main.tf`
Abra o arquivo `main.tf` e inspecione o recurso:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = "Local Exec Example"
  }

  provisioner "local-exec" {
    command = "echo 'Instância criada: ${self.id} | IP: ${self.public_ip}' > instance_info.txt"
  }
}
```
- **`local-exec`:** Dispara a instrução shell localmente na máquina onde o Terraform está rodando assim que a criação na AWS é concluída.
- **`self`:** Objeto especial que permite acessar atributos do próprio recurso durante o provisionamento.

### Passo 2: Execução do Ciclo de Vida
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Observe a saída no terminal: o Terraform executa o comando `local-exec` e exibe o log de execução diretamente no stdout.*

---

## 🧪 Validação & Critérios de Aceite

1. **Inspeção do Arquivo de Inventário Local:**
   Verifique o arquivo gerado pelo provisionador:
   ```bash
   cat instance_info.txt
   ```
   *Critério de Aceite:* O arquivo deve conter o ID da instância e o endereço IP público alocado.
2. **Inspeção de Logs do Terraform:**
   ```bash
   terraform show
   ```

---

## 🧹 Cleanup

Para destruir a instância e higienizar arquivos locais:
```bash
terraform destroy -auto-approve
rm -f instance_info.txt
cd ..
```

---

## 💡 Desafios Complementares

1. **Trigger on Destroy:** Configure um segundo bloco de provisionamento que execute apenas na destruição do recurso:
   ```hcl
   provisioner "local-exec" {
     when    = destroy
     command = "echo 'Instância destruída em: $(date)' >> audit.log"
   }
   ```
2. **Exportação de Inventário Ansible:** Ajuste o comando para gravar o IP público em um formato de inventário INI do Ansible (`echo "${self.public_ip} ansible_user=ec2-user" > hosts.ini`).
