# Lab 07 - Estruturas de Repetição com Count (Múltiplas Instâncias)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Meta-argumento `count`  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Aprender a escalar o provisionamento de infraestrutura a partir de um único bloco declarativo usando o meta-argumento `count`:
1. Compreender o funcionamento e ciclo de vida de recursos indexados via `count`.
2. Utilizar a variável interna `count.index` para parametrização dinâmica de nomes e tags.
3. Compreender a representação de listas indexadas no estado (`aws_instance.count_example[0]`).
4. Analisar os limites operacionais e o comportamento de substituição por mudança de índice.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab07-count
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Recurso no `main.tf`
Abra o arquivo `main.tf` e observe a declaração indexada:
```hcl
resource "aws_instance" "count_example" {
  count         = 3
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = "Instance ${count.index + 1}"
  }
}
```
- **`count = 3`:** Instancia o bloco 3 vezes sequencialmente.
- **`${count.index + 1}`:** Acessa o índice base zero (0, 1, 2) e gera os nomes `Instance 1`, `Instance 2` e `Instance 3`.

### Passo 2: Inicialização e Planejamento
```bash
terraform init
terraform plan
```
*Observe que o Terraform identifica cada recurso com sua notação de array: `aws_instance.count_example[0]`, `[1]` e `[2]`.*

### Passo 3: Provisionamento em Lote
```bash
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

1. **Validação via AWS CLI:**
   Liste as instâncias criadas com suas respectivas tags de índice:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='Instance *'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Critério de Aceite:* Devem figurar 3 instâncias com estado `running` e nomes `Instance 1`, `Instance 2` e `Instance 3`.
2. **Inspeção de Estado Indexado:**
   ```bash
   terraform state list
   ```
   *Critério de Aceite:* Exibe explicitamente as 3 instâncias separadas por colchetes de índice.

---

## 🧹 Cleanup

Desprovisione as instâncias para liberar a conta de testes:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Escalação Condicional:** Declare uma variável booleana `variable "enable_monitoring" { default = true }`. Use a expressão ternária `count = var.enable_monitoring ? 1 : 0` para criar um recurso condicionalmente.
2. **Exportação de Lista de IPs:** Adicione um bloco `output "instance_ips"` que exponha a lista com todos os IPs públicos criados usando a sintaxe splat: `value = aws_instance.count_example[*].public_ip`.
