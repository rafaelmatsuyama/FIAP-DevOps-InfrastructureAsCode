# Lab 08 - Estruturas de Repetição com For Each (Mapeamento de Instâncias)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Meta-argumento `for_each`  
**Duração Estimada:** 20 minutos  

---

## 🎯 Objetivo do Lab

Dominar o meta-argumento `for_each` para gerenciamento determinístico de coleções sem vulnerabilidades de indexação:
1. Compreender as vantagens arquiteturais do `for_each` sobre o `count` na prevenção de destruições acidentais em cascata.
2. Utilizar a função de conversão `toset()` para transformar listas em conjuntos de chaves únicas.
3. Mapear atributos dinâmicos consumindo as variáveis de contexto `each.key` e `each.value`.
4. Inspecionar o mapeamento de chaves nominais no arquivo de estado (`aws_instance.foreach_example["web1"]`).

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab08-foreach
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise do Mapeamento no `main.tf`
Abra o arquivo `main.tf` e analise a declaração:
```hcl
variable "instance_names" {
  type    = list(string)
  default = ["web1", "web2", "web3"]
}

resource "aws_instance" "foreach_example" {
  for_each      = toset(var.instance_names)
  ami           = "ami-0de716d6197524dd9"
  instance_type = "t2.micro"

  tags = {
    Name = each.value
  }
}
```
- **`toset()`:** Converte a lista em um conjunto com garantia de chaves exclusivas.
- **`each.value`:** Vincula a string da iteração atual como tag `Name` da respectiva instância EC2.

### Passo 2: Inicialização e Planejamento
```bash
terraform init
terraform plan
```
*Observe que o Terraform rastreia cada recurso através de chaves nominais (`["web1"]`, `["web2"]`, `["web3"]`) em vez de índices ordinais numéricos.*

### Passo 3: Provisionamento Declarativo
```bash
terraform apply -auto-approve
```

---

## 🧪 Validação & Critérios de Aceite

1. **Validação via AWS CLI:**
   Liste as instâncias criadas:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='web1','web2','web3'" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Critério de Aceite:* As três instâncias devem figurar com estado `running` e os nomes declarados.
2. **Inspeção de Chaves no State:**
   ```bash
   terraform state list
   ```
   *Critério de Aceite:* Cada recurso é referenciado pelo seu rótulo string entre aspas (`aws_instance.foreach_example["web1"]`).

---

## 🧹 Cleanup

Desprovisione os recursos para evitar custos na nuvem:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Iteração sobre Maps com Múltiplos Atributos:** Modifique `var.instance_names` para um mapa:
   ```hcl
   variable "instances" {
     type = map(object({ type = string, env = string }))
     default = {
       "web" = { type = "t2.micro", env = "dev" }
       "api" = { type = "t3.micro", env = "prod" }
     }
   }
   ```
   Ajuste `for_each = var.instances` e configure `instance_type = each.value.type`.
2. **Saída Mapeada:** Crie um output que retorne um mapa relacionando cada nome de servidor ao seu respectivo IP público.
