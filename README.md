# n8n-self-hosting

# n8n Self-Hosting Evolution

Este projeto provisiona uma infraestrutura na AWS para auto-hospedagem do n8n e da Evolution API, utilizando Terraform para automação.

## Arquitetura

A infraestrutura é dividida em duas stacks principais gerenciadas pelo Terraform:

1.  **`00-remote-state-backend-stack`**: Cria um bucket S3 versionado para armazenar o estado do Terraform (`.tfstate`), garantindo um backend de estado remoto, seguro e centralizado.
2.  **`01-n8n-stack`**: Provisiona todos os recursos necessários para a aplicação, incluindo:
    *   **VPC**: Uma Virtual Private Cloud para isolar os recursos da aplicação.
    *   **Subnets Públicas e Privadas**: Para organização e segurança da rede.
    *   **Internet Gateway**: Para permitir o acesso à internet a partir da VPC.
    *   **Tabelas de Rota**: Para controlar o fluxo de tráfego de rede.
    *   **EC2 Instance**: Uma instância `t4g.small` para hospedar as aplicações n8n e Evolution API. A instância utiliza um script `user_data.sh` para o bootstrap inicial.
    *   **Elastic IP**: Um endereço IP público estático associado à instância EC2.
    *   **Security Group**: Regras de firewall para controlar o tráfego de entrada e saída da instância EC2, permitindo acesso nas portas `80`, `443` e `5678`.
    *   **IAM Role**: Uma role IAM com permissões para acesso via AWS Systems Manager (SSM), facilitando o gerenciamento da instância.
    *   **Route 53 Records**: Registros DNS do tipo "A" para os domínios `n8n2.alisriosti.com.br` e `evolution-api2.alisriosti.com.br`, apontando para o Elastic IP da instância.

## Pré-requisitos

*   [Terraform](https://www.terraform.io/downloads.html) instalado.
*   Credenciais da AWS configuradas.
*   Um domínio registrado no Route 53.

## Como usar

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/alisrios/n8n-self-hosting-evolution.git
    cd n8n-self-hosting-evolution
    ```

2.  **Configure as variáveis:**
    *   Renomeie os arquivos `*.tfvars.example` para `*.tfvars` em cada diretório de stack.
    *   Preencha os valores das variáveis nos arquivos `*.tfvars` de acordo com o seu ambiente.

3.  **Provisione o backend de estado remoto:**
    ```bash
    cd 00-remote-state-backend-stack
    terraform init
    terraform apply
    ```

4.  **Provisione a stack da aplicação:**
    ```bash
    cd ../01-n8n-stack
    terraform init
    terraform apply
    ```

## Destruindo a infraestrutura

Para remover todos os recursos criados, execute o comando `terraform destroy` em cada diretório de stack, na ordem inversa da criação:

```bash
cd 01-n8n-stack
terraform destroy

cd ../00-remote-state-backend-stack
terraform destroy
```
