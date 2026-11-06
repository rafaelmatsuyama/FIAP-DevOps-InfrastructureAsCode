# Lab 09 - Expressões Avançadas com Loops For (Transformações de Dados)

**Curso:** MBA em DevOps Engineering  
**Plataforma / Ambiente:** GitHub Codespaces (AWS Academy / Nuvem AWS)  
**Linguagem / Stack:** Terraform 1.9+, AWS Provider, EC2, Expressões `for` do HCL  
**Duração Estimada:** 25 minutos  

---

## 🎯 Objetivo do Lab

Dominar o poder das expressões funcionais com loops `for` no HCL para transformação dinâmica de estruturas de dados:
1. Compreender a sintaxe de compreensão de listas e mapas (`[for k, v in col : ...]` e `{for item in list : k => v}`).
2. Transformar dicionários de configuração em listas estruturadas de objetos.
3. Consumir coleções transformadas diretamente no meta-argumento `for_each` para provisionar recursos com especificações heterogêneas.
4. Exportar mapas de saída filtrados utilizando cláusulas condicionais `if`.

---

## 📋 Pré-requisitos & Materiais

- Credenciais ativas da **AWS Academy** em `~/.aws/credentials`.
- Terminal posicionado no diretório:
  ```bash
  cd lab09-for
  ```

---

## 🚀 Passo a Passo Guiado

### Passo 1: Análise das Transformações em `locals`
Abra o arquivo `main.tf` e examine a manipulação das estruturas locais:
```hcl
locals {
  instance_types = {
    web1 = "t2.micro"
    web2 = "t2.small"
    web3 = "t2.medium"
  }

  instance_list = [for name, type in local.instance_types : {
    name = name
    type = type
  }]
}
```
- **`instance_types`:** Dicionário mapeando hostname para o tamanho da instância EC2 desejada.
- **`instance_list`:** Itera sobre as tuplas `name, type` e projeta uma lista de objetos padronizados.

### Passo 2: Projeção de Mapa para o `for_each`
Observe como a lista é reconvertida em mapa único para consumo pelo `for_each`:
```hcl
resource "aws_instance" "for_example" {
  for_each      = { for instance in local.instance_list : instance.name => instance }
  ami           = "ami-0de716d6197524dd9"
  instance_type = each.value.type

  tags = {
    Name = each.key
  }
}
```

### Passo 3: Execução e Aplicação
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Repare no plano como `web1` recebe `t2.micro`, `web2` recebe `t2.small` e `web3` recebe `t2.medium`.*

---

## 🧪 Validação & Critérios de Aceite

1. **Validação via AWS CLI:**
   Liste as instâncias criadas com seus respectivos tipos de máquina:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values='web1','web2','web3'" --query "Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key=='Name'].Value|[0]]" --output table
   ```
   *Critério de Aceite:* Cada instância deve apresentar o `InstanceType` correspondente à regra definida no dicionário.
2. **Inspeção de Outputs:**
   ```bash
   terraform output
   ```

---

## 🧹 Cleanup

Desprovisione a infraestrutura para economizar créditos:
```bash
terraform destroy -auto-approve
cd ..
```

---

## 💡 Desafios Complementares

1. **Filtragem Condicional em Expressão For:** Crie um `output "micro_instances"` que utilize uma cláusula `if` na compreensão para retornar apenas os nomes dos servidores cujo tipo seja `"t2.micro"`:
   ```hcl
   output "micro_instances" {
     value = [for k, v in local.instance_types : k if v == "t2.micro"]
   }
   ```
2. **Mapeamento de Hostnames para IPs:** Construa uma expressão que gere um dicionário `{ "web1" => "IP_PUBLICO_1", ... }` a partir do recurso `aws_instance.for_example`.
