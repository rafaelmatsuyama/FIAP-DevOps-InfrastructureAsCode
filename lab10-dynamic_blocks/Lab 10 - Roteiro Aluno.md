# Lab 10 - Blocos Dinâmicos (Dynamic Blocks no Terraform)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, EBS, `dynamic` blocks  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Aprender a eliminar a duplicação de sub-blocos estruturais aninhados em manifestos Terraform utilizando `dynamic`:
1. Compreender a finalidade e a semântica de blocos dinâmicos (`dynamic "<block>" { for_each = ... content { ... } }`).
2. Iterar sobre listas de configurações de armazenamento para anexar múltiplos volumes EBS (`ebs_block_device`) a uma instância EC2.
3. Mapear propriedades internas consumindo o iterador nominal de contexto (`ebs_block_device.value.*`).
4. Auditar a criação de volumes em bloco no console e via CLI da AWS.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab10-dynamic_blocks
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Bloco Dinâmico no `main.tf`
Abra o arquivo `main.tf` e examine a declaração do recurso:
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      delete_on_termination = true
    }
  }
}
```
- **`dynamic "ebs_block_device"`:** Declara que múltiplos sub-blocos repetitivos serão injetados dentro do recurso `aws_instance`.
- **`for_each = var.ebs_volumes`:** Itera sobre a lista de objetos definidos nas variáveis.
- **`content`:** Constrói o corpo de cada sub-bloco consumindo `ebs_block_device.value`.

### Passo 2: Inicialização e Planejamento
```bash
terraform init
terraform plan
```
*Observe que o plano exibirá uma única instância computacional contendo múltiplos blocos de disco adicionais configurados.*

### Passo 3: Provisionamento Declarativo
```bash
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

1. **Validação via AWS CLI:**
   Consulte os volumes anexados à instância:
   ```bash
   aws ec2 describe-volumes --filters "Name=attachment.device,Values='/dev/sdb','/dev/sdc'" --query "Volumes[*].[VolumeId,Size,VolumeType,State]" --output table
   ```
   *Critério de Aceite:* Devem figurar os volumes adicionais anexados com os tamanhos configurados (10GB e 20GB).
2. **Inspeção de Estado:**
   ```bash
   terraform show
   ```
   *Critério de Aceite:* O bloco `ebs_block_device` exibe os dois dispositivos de armazenamento persistidos no state.

---

## 🧹 Cleanup

Desprovisione a instância e seus volumes anexados:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Dynamic Ingress em Security Group:** Aplique o padrão `dynamic` para gerar regras de entrada (`dynamic "ingress"`) em um recurso `aws_security_group`, iterando sobre uma lista de portas `[22, 80, 443]`.
2. **Criptografia Automática:** Adicione a flag `encrypted = true` dentro do bloco `content` dos volumes EBS para garantir criptografia em repouso.
