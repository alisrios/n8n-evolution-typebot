#!/bin/bash

# Atualizar pacotes e instalar Git e Docker
sudo yum update -y
sudo yum install -y git docker

# Adicionar usuários ao grupo Docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker ssm-user
id ec2-user ssm-user
sudo newgrp docker

# Ativar e iniciar o serviço Docker
sudo systemctl enable docker
sudo systemctl start docker

# Instalar Docker Compose 2 para ARM64
DOCKER_COMPOSE_VERSION="v2.23.3"
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Adicionar Swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab

# Instalar Node.js e npm para ARM64
curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -
sudo yum install -y nodejs

# Cria diretórios para volumes persistentes
sudo mkdir -p /home/ec2-user/n8n

# Move-se para o diretório de trabalho
cd /home/ec2-user/n8n

# Define permissões corretas
sudo chown -R $USER:$USER /home/ec2-user/n8n

# Cria um arquivo .env com variáveis sensíveis (modifique conforme necessário)
cat <<EOF > .env
AUTHENTICATION_TYPE=api_key
AUTHENTICATION_API_KEY=LVKX4QvOEG7CrsvxndhxXZPjUq9deFlhDXvgREim9I9LiJHg1DbM9WprraXLydLf
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
LANGUAGE=pt-BR
CONFIG_SESSION_PHONE_CLIENT=Integracao
CONFIG_SESSION_PHONE_NAME=Chrome
#CONFIG_SESSION_PHONE_VERSION=2.3000.1029425805

# Database #
MYSQL_ROOT_PASSWORD=root
TZ=America/Sao_Paulo
# Habilitar o uso do banco de dados
DATABASE_ENABLED=true
# Escolher o provedor do banco de dados: postgresql ou mysql
#DATABASE_PROVIDER=mysql
DATABASE_PROVIDER=postgresql
POSTGRES_USER="user"
POSTGRES_PASSWORD="123456"
PGADMIN_DEFAULT_EMAIL="alisrios@gmail.com"
PGADMIN_DEFAULT_PASSWORD=123456
# URI de conexão com o banco de dados
#DATABASE_CONNECTION_URI='mysql://root:root@mysql:3306/evolution'
DATABASE_CONNECTION_URI="postgresql://postgres:123456@postgres:5432/evolution?schema=public"
# Nome do cliente para a conexão do banco de dados
DATABASE_CONNECTION_CLIENT_NAME=evolution

# Escolha os dados que você deseja salvar no banco de dados da aplicação
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true

# Redis #
# Habilitar o cache Redis
CACHE_REDIS_ENABLED=true
# URI de conexão com o Redis
CACHE_REDIS_URI=redis://redis:6379/0
# Prefixo para diferenciar os dados de diferentes instalações que utilizam o mesmo Redis
CACHE_REDIS_PREFIX_KEY=evolution_v2
# Habilitar para salvar as informações de conexão no Redis ao invés do banco de dados
CACHE_REDIS_SAVE_INSTANCES=false
# Habilitar o cache local
CACHE_LOCAL_ENABLED=false

# Webhook #
#WEBHOOK_GLOBAL_ENABLED=true
#WEBHOOK_GLOBAL_URL='https://dashboard.actionsolucoes.dev.br/webhook/'
#WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false

# Typebot #
TYPEBOT_ENABLED=true
TYPEBOT_API_VERSION=latest

# Chatwoot #
CHATWOOT_ENABLED=false
CHATWOOT_MESSAGE_READ=true
CHATWOOT_MESSAGE_DELETE=false
CHATWOOT_IMPORT_PLACEHOLDER_MEDIA_MESSAGE=true

# AWS S3 #
S3_ENABLED=false

# N8N #
N8N_SECURE_COOKIE=false
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n2.alisriosti.com.br/
SSL_EMAIL=alisrios@gmail.com.br
SUBDOMAIN=n8n2
SUBDOMAIN2=evolution-api2
DOMAIN_NAME=alisriosti.com.br
GENERIC_TIMEZONE=America/Sao_Paulo
EOF

# Cria o arquivo docker-compose.yml
cat <<EOF > compose.yml
services:
  evolution-api:
    container_name: evolution_api
    image: evoapicloud/evolution-api:latest
    restart: always
    env_file:
      - .env
    volumes:
      - evolution_store:/evolution/store
      - evolution_instances:/evolution/instances
    networks:
      - evolution-net
    labels:
      - "traefik.enable=true"
      - traefik.http.routers.evolution-api.rule=Host("\${SUBDOMAIN2}.\${DOMAIN_NAME}")
      - "traefik.http.routers.evolution-api.entrypoints=websecure"
      - "traefik.http.routers.evolution-api.tls.certresolver=myresolver"
      - "traefik.http.services.evolution-api.loadbalancer.server.port=8080"

  redis:
    image: redis:latest
    container_name: redis
    command: redis-server --port 6379 --appendonly yes
    volumes:
      - evolution_redis:/data
    networks:
      - evolution-net
    expose:
      - 6379

  postgres:
    image: postgres:16
    container_name: postgres
    restart: always
    environment:
      - POSTGRES_PASSWORD=123456
      - POSTGRES_USER=postgres
      - POSTGRES_DB=evolution
    volumes:
      - postgres_data:/var/lib/postgresql/data
    expose:
      - 5432
    networks:
      - evolution-net

  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped
    networks:
      - evolution-net
    env_file:
      - .env
    labels:
      - "traefik.enable=true"
      - traefik.http.routers.n8n.rule=Host("\${SUBDOMAIN}.\${DOMAIN_NAME}")
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=myresolver"

  traefik:
    image: traefik:v3.5.4
    container_name: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - --certificatesresolvers.myresolver.acme.email=\${SSL_EMAIL}
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8081:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "letsencrypt:/letsencrypt"
    networks:
      - evolution-net

volumes:
  evolution_store:
  evolution_instances:
  postgres_data:
  evolution_redis:
  n8n_data:
  letsencrypt:

networks:
  evolution-net:
    name: evolution-net
    driver: bridge   
EOF

# Inicia os containers
sudo docker compose up -d