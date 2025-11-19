# N8N, Evolution API & Typebot Self-Hosting on AWS

Este projeto fornece uma infraestrutura totalmente automatizada para auto-hospedagem do N8N, Evolution API e Typebot na AWS usando Terraform. Ele foi projetado para segurança, escalabilidade e facilidade de implantação.

## ✨ Principais Funcionalidades

-   **Implantação Automatizada**: Provisiona toda a infraestrutura AWS com Terraform, incluindo VPC, subnets, security groups, EC2 e Route 53.
-   **Seguro por Padrão**: Gera automaticamente chaves de segurança (`AUTHENTICATION_API_KEY` e `N8N_ENCRYPTION_KEY`) durante o bootstrap da instância.
-   **Gerenciamento de Estado Remoto**: Utiliza bucket S3 com versionamento para armazenar o estado do Terraform de forma segura e colaborativa.
-   **Arquitetura ARM64**: Utiliza instância EC2 `t4g.small` (AWS Graviton) oferecendo melhor custo-benefício e performance.
-   **SSL Automático**: Certificados SSL gerenciados automaticamente via Traefik e Let's Encrypt.
-   **DNS Gerenciado**: Registros Route 53 configurados automaticamente para n8n, Evolution API, Typebot Builder e Typebot Viewer.
-   **Banco de Dados Persistente**: PostgreSQL containerizado com volumes persistentes para n8n e Evolution API.
-   **Cache Redis**: Implementado para melhor performance da Evolution API.
-   **Acesso Seguro via SSM**: Acesso à instância EC2 via AWS Systems Manager, sem necessidade de chaves SSH.

## ✨ Funcionalidades Avançadas

### Configuração Automática do S3
- **Bucket S3** criado automaticamente para uploads do Typebot
- **Credenciais IAM** geradas e injetadas via tags da instância EC2
- **CORS** configurado para permitir uploads dos domínios do Typebot
- **Política de acesso público** para leitura de imagens
- **Force destroy** habilitado para facilitar limpeza

### URLs Dinâmicas
Todas as URLs são geradas dinamicamente baseadas nas variáveis exportadas no `user_data.sh`:

**Variáveis exportadas** (definidas no início do script):
```bash
export SUBDOMAIN_N8N=n8n
export SUBDOMAIN_EVO=evolution-api
export SUBDOMAIN_TYPEBOT=typebot
export SUBDOMAIN_TYPEBOT_VIEWER=typebot-viewer
export DOMAIN_NAME_OWNER=alisriosti.com.br
export SSL_EMAIL_OWNER=alisrios@gmail.com.br
```

**URLs geradas automaticamente**:
- `WEBHOOK_URL` → `https://${SUBDOMAIN_N8N}.${DOMAIN_NAME_OWNER}/`
- `NEXTAUTH_URL` → `https://${SUBDOMAIN_TYPEBOT}.${DOMAIN_NAME_OWNER}`
- `NEXT_PUBLIC_VIEWER_URL` → `https://${SUBDOMAIN_TYPEBOT_VIEWER}.${DOMAIN_NAME_OWNER}`

**Vantagens**:
- Facilita a manutenção (altere apenas as variáveis exportadas)
- Permite múltiplas instalações com diferentes subdomínios
- Evita duplicação de valores no código
- Garante consistência entre `.env` e `compose.yml`

## 🏗️ Arquitetura

A infraestrutura é dividida em duas stacks principais do Terraform:

### 1. `00-remote-state-backend-stack`
Cria a infraestrutura base para gerenciamento de estado:
- **Bucket S3** com versionamento habilitado para armazenar o estado do Terraform
- Configuração de tags padrão para organização de recursos

### 2. `01-n8n-stack`
Provisiona toda a infraestrutura da aplicação:

#### Rede (VPC)
- VPC customizada com CIDR `10.0.0.0/24`
- 2 subnets públicas (us-east-1a e us-east-1b) para alta disponibilidade
- 2 subnets privadas (us-east-1a e us-east-1b) para recursos internos
- Internet Gateway para acesso externo
- Route tables públicas e privadas

#### Computação
- **Instância EC2 t4g.small** (ARM64/Graviton)
  - AMI: Amazon Linux 2023 ARM64
  - Volume EBS de 30GB criptografado
  - User data script para bootstrap automático
- **Elastic IP** para endereço IP público estático

#### Segurança
- **Security Group** permitindo:
  - Porta 80 (HTTP)
  - Porta 443 (HTTPS)
  - Porta 5678 (n8n webhook)
  - Todo tráfego de saída
- **IAM Role** com permissões para:
  - SSM (acesso remoto seguro)
  - ECR e ECS (gerenciamento de containers)
  - S3 (armazenamento)
  - Secrets Manager (gerenciamento de segredos)

#### DNS
- Registros Route 53 tipo A para:
  - `n8n.alisriosti.com.br`
  - `evolution-api.alisriosti.com.br`
  - `typebot.alisriosti.com.br`
  - `typebot-viewer.alisriosti.com.br`

#### Aplicação (Docker Compose)
Containers executados na instância EC2:
- **n8n**: Plataforma de automação de workflows
- **Evolution API**: API para integração com WhatsApp
- **Typebot Builder**: Interface de construção de chatbots
- **Typebot Viewer**: Visualizador de chatbots
- **PostgreSQL 16**: Banco de dados compartilhado (databases: evolution, n8n e typebot)
- **Redis**: Cache compartilhado (database 0 para Evolution API, database 1 para Typebot)
- **Traefik**: Reverse proxy com SSL automático via Let's Encrypt

#### Armazenamento (S3)
- **Bucket S3**: Armazenamento de uploads do Typebot (imagens, arquivos)
- **IAM User**: Credenciais dedicadas para acesso ao S3
- **CORS**: Configurado para permitir uploads do Typebot
- **Acesso Público**: Leitura pública habilitada para servir imagens

## 📋 Pré-requisitos

-   [Terraform](https://www.terraform.io/downloads.html) >= 1.11.0 instalado
-   AWS CLI instalado e configurado com credenciais válidas
-   Domínio registrado com Zona Hospedada no AWS Route 53
-   IAM Role configurada para Terraform (ex: `TerraformAssumeRole`)
-   Permissões AWS necessárias:
    - EC2, VPC, EIP
    - S3
    - Route 53
    - IAM
    - Systems Manager

## 🚀 Passos para Implantação

### 1. Clone o Repositório
```bash
git clone https://github.com/alisrios/n8n-self-hosting-evolution.git
cd n8n-self-hosting-evolution
```

### 2. Configure as Variáveis do Terraform

#### Stack 00 - Remote State Backend
Edite `00-remote-state-backend-stack/variables.tf` e ajuste:
- `auth.assume_role_arn`: ARN da sua IAM Role para Terraform
- `auth.region`: Região AWS (padrão: us-east-1)
- `remote_backend.s3_bucket`: Nome do bucket S3 (deve ser único globalmente)

#### Stack 01 - Aplicação
Edite os seguintes arquivos em `01-n8n-stack/`:

**variables.tf**:
- `aws_provider.assume_role.role_arn`: ARN da sua IAM Role
- `aws_provider.region`: Região AWS
- `vpc.*`: Configurações de rede (opcional, valores padrão já configurados)

**route53.tf**:
- Substitua `alisriosti.com.br` pelo seu domínio
- Ajuste os subdomínios `n8n`, `evolution-api`, `typebot` e `typebot-viewer` conforme necessário

**user_data.sh**:
- Ajuste as variáveis exportadas no início do script (linhas 54-59):
  - **Domain Configuration** (variáveis exportadas):
    - `SUBDOMAIN_N8N`: Subdomínio do n8n (padrão: n8n)
    - `SUBDOMAIN_EVO`: Subdomínio da Evolution API (padrão: evolution-api)
    - `SUBDOMAIN_TYPEBOT`: Subdomínio do Typebot Builder (padrão: typebot)
    - `SUBDOMAIN_TYPEBOT_VIEWER`: Subdomínio do Typebot Viewer (padrão: typebot-viewer)
    - `DOMAIN_NAME_OWNER`: Seu domínio (ex: alisriosti.com.br)
    - `SSL_EMAIL_OWNER`: Seu email para certificados Let's Encrypt
  - Essas variáveis são usadas para gerar automaticamente:
    - URLs dos serviços (`WEBHOOK_URL`, `NEXTAUTH_URL`, `NEXT_PUBLIC_VIEWER_URL`)
    - Registros DNS no Route53
    - Configurações do Traefik
  - Senhas do PostgreSQL e PgAdmin (recomendado alterar)
  - **Typebot SMTP**: Configure para autenticação por email
    - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`: Configurações do servidor SMTP
    - `SMTP_PASSWORD`: Senha de app do Gmail (gere em https://myaccount.google.com/apppasswords)
    - `NEXT_PUBLIC_SMTP_FROM`: Email remetente para magic links
    - `DISABLE_SIGNUP`: `true` para desabilitar registro público
  - **Typebot S3**: Configurado automaticamente via tags da instância EC2
    - As credenciais S3 são obtidas automaticamente das tags da instância
    - Não é necessário configurar manualmente

### 3. Implante o Backend de Estado Remoto
```bash
cd 00-remote-state-backend-stack
terraform init
terraform plan
terraform apply
```

### 4. Configure o Backend Remoto na Stack Principal
Edite `01-n8n-stack/state.config.tf` e ajuste:
- `bucket`: Nome do bucket criado no passo anterior
- `region`: Mesma região configurada

### 5. Implante a Stack da Aplicação
```bash
cd ../01-n8n-stack
terraform init
terraform plan
terraform apply
```

### 6. Aguarde a Inicialização
Após o `terraform apply`, aguarde aproximadamente 5-10 minutos para:
- Instância EC2 inicializar
- Docker e containers serem instalados
- Certificados SSL serem gerados
- Aplicações ficarem disponíveis

## 🔑 Acesso às Aplicações

### URLs de Acesso
Após a implantação bem-sucedida, acesse:
- **n8n**: `https://n8n.seudominio.com.br`
- **Evolution API**: `https://evolution-api.seudominio.com.br`
- **Typebot Builder**: `https://typebot.seudominio.com.br`
- **Typebot Viewer**: `https://typebot-viewer.seudominio.com.br`
- **Traefik Dashboard**: `http://seu-ip:8081`

### Chaves de Segurança
As chaves são geradas automaticamente durante o bootstrap da instância EC2:

**Para recuperar a chave da Evolution API**:
```bash
# Via AWS Systems Manager (SSM)
aws ssm start-session --target <instance-id>

# Dentro da instância
cat /home/ec2-user/n8n/.evolution_api
```

Ou verifique os logs do cloud-init:
```bash
sudo cat /var/log/cloud-init-output.log | grep -A 2 "Evolution API Key"
```

### Credenciais Padrão
**PostgreSQL**:
- Host: `postgres` (interno ao Docker)
- Usuário: `postgres`
- Senha: `123456` (altere no `user_data.sh`)
- Databases: `evolution`, `n8n` e `typebot`

**PgAdmin** (se habilitado):
- Email: `alisrios@gmail.com` (altere no `user_data.sh`)
- Senha: `123456` (altere no `user_data.sh`)

**Redis**:
- Host: `redis` (interno ao Docker)
- Porta: `6379`
- Database 0: Evolution API
- Database 1: Typebot

**Typebot**:
- Autenticação: Email (magic link via SMTP)
- Email admin: Configurado em `ADMIN_EMAIL`
- Primeiro acesso: Digite seu email e clique no link recebido por email

⚠️ **IMPORTANTE**: Altere todas as senhas padrão antes de usar em produção!

## � Geerenciamento e Manutenção

### Acessar a Instância EC2
```bash
# Via AWS Systems Manager (recomendado - sem necessidade de SSH)
aws ssm start-session --target <instance-id>

# Ou via AWS Console
# EC2 > Instances > Connect > Session Manager
```

### Verificar Status dos Containers
```bash
cd /home/ec2-user/n8n
sudo docker compose ps
sudo docker compose logs -f
```

### Reiniciar Serviços
```bash
cd /home/ec2-user/n8n
sudo docker compose restart
```

### Backup dos Dados

**Volumes Docker** (persistem os dados em):
- `/var/lib/docker/volumes/n8n_n8n_data` - Dados do n8n
- `/var/lib/docker/volumes/n8n_postgres_data` - Banco de dados PostgreSQL
- `/var/lib/docker/volumes/n8n_evolution_store` - Dados da Evolution API
- `/var/lib/docker/volumes/n8n_evolution_instances` - Instâncias da Evolution API
- `/var/lib/docker/volumes/n8n_evolution_redis` - Cache Redis
- `/var/lib/docker/volumes/n8n_letsencrypt` - Certificados SSL

**Bucket S3** (uploads do Typebot):
- Bucket: `typebot-uploads-{account-id}`
- Versionamento habilitado
- Recomenda-se configurar lifecycle policies para arquivos antigos

**Recomendações**:
- Configure snapshots automáticos do volume EBS da instância
- Configure backup do bucket S3 (S3 Versioning já está habilitado)
- Exporte regularmente os dados do PostgreSQL

### Atualizar Aplicações
```bash
cd /home/ec2-user/n8n
sudo docker compose pull
sudo docker compose up -d
```

## 📊 Custos Estimados (us-east-1)

Estimativa mensal aproximada:
- EC2 t4g.small: ~$15/mês
- EBS 30GB: ~$3/mês
- Elastic IP: Grátis (enquanto associado)
- Route 53: ~$0.50/mês por zona hospedada + $0.50/mês por registro
- S3 (estado Terraform): < $1/mês
- S3 (uploads Typebot): ~$0.023/GB armazenado + $0.09/GB transferido
- Transferência de dados: Variável

**Total estimado**: ~$20-30/mês (pode variar conforme uso e volume de uploads)

## 🛡️ Segurança

### Recomendações de Produção
1. **Altere todas as senhas padrão** no `user_data.sh`
2. **Restrinja o Security Group** para IPs específicos se possível
3. **Habilite MFA** na conta AWS
4. **Configure backups automáticos** dos volumes EBS
5. **Monitore logs** via CloudWatch
6. **Atualize regularmente** as imagens Docker
7. **Use AWS Secrets Manager** para credenciais sensíveis
8. **Habilite CloudTrail** para auditoria

### Portas Expostas
- 80 (HTTP - redireciona para HTTPS)
- 443 (HTTPS - n8n, Evolution API e Typebot)
- 5678 (n8n webhooks)
- 8081 (Traefik dashboard - considere restringir)

## 🐛 Troubleshooting

### Containers não iniciam
```bash
# Verificar logs
sudo docker compose logs

# Verificar recursos
free -h
df -h
```

### SSL não funciona
- Verifique se as portas 80 e 443 estão abertas no Security Group
- Confirme que os registros DNS estão propagados: `nslookup n8n.seudominio.com.br`
- Verifique logs do Traefik: `sudo docker compose logs traefik`
- **Rate limit do Let's Encrypt**: Se houver muitas tentativas falhas, aguarde 1 hora

### Typebot não envia emails
- Verifique se configurou a senha de app do Gmail corretamente
- Teste as credenciais SMTP: `sudo docker compose logs typebot-builder`
- Confirme que a verificação em 2 etapas está ativa no Gmail
- Verifique se o email não está na pasta de spam

### Typebot não faz upload de imagens
- Verifique se as credenciais S3 estão corretas: `cat .env | grep ^S3_`
- Teste o acesso ao bucket: `aws s3 ls s3://typebot-uploads-{account-id}/`
- Verifique os logs: `docker logs typebot-builder --tail 50`
- Confirme que o CORS está configurado corretamente no bucket S3
- Verifique se o domínio do Typebot está na lista de origens permitidas no CORS

### Não consigo acessar via SSM
- Verifique se a IAM Role está anexada à instância
- Confirme que a política `AmazonSSMManagedInstanceCore` está presente
- Aguarde alguns minutos após a criação da instância

## 💣 Destruindo a Infraestrutura

Para evitar cobranças contínuas, destrua os recursos na ordem inversa:

### 1. Destrua a Stack da Aplicação
```bash
cd 01-n8n-stack
terraform destroy
```

### 2. Destrua o Backend de Estado Remoto
⚠️ **ATENÇÃO**: Isso removerá o bucket S3 com o estado do Terraform!

```bash
cd ../00-remote-state-backend-stack
terraform destroy
```

## 📝 Estrutura do Projeto

```
.
├── 00-remote-state-backend-stack/
│   ├── main.tf              # Provider AWS
│   ├── s3.tf                # Bucket S3 para estado remoto
│   ├── variables.tf         # Variáveis da stack
│   └── output.tf            # Outputs da stack
│
├── 01-n8n-stack/
│   ├── main.tf                  # Provider AWS
│   ├── state.config.tf          # Configuração backend S3
│   ├── variables.tf             # Variáveis da stack
│   ├── vpc.tf                   # VPC principal
│   ├── vpc.public-subnets.tf
│   ├── vpc.private-subnets.tf
│   ├── vpc.internet-gateway.tf
│   ├── vpc.public-route-table.tf
│   ├── vpc.private-route-table.tf
│   ├── instance.ec2.tf          # Instância EC2 (com tags S3)
│   ├── eip.tf                   # Elastic IP
│   ├── security.group.tf        # Security Group
│   ├── iam.tf                   # IAM Roles e Policies
│   ├── route53.tf               # Registros DNS
│   ├── s3-typebot.tf            # Bucket S3 para Typebot
│   ├── user_data.sh             # Script de bootstrap
│   ├── configure-s3.sh          # Script auxiliar (opcional)
│   └── outputs.tf               # Outputs da stack
│
└── README.md
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir melhorias
- Enviar pull requests

## 📄 Licença

Este projeto é fornecido "como está", sem garantias de qualquer tipo.
