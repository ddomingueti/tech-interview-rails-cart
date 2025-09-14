# Desafio técnico e-commerce

## O Desafio - Carrinho de compras
O desafio consiste em uma API para gerenciamento do um carrinho de compras de e-commerce.

Realizado a evolução do código base para conter mais três endpoints, respeitando as regras de negócio definidas e também o formato de saída.

Endpoints criados:
POST /carts : registra um novo produto no carrinho, e se não tiver um carrinho ele é criado automaticamente
POST /carts/add_item : adiciona um item existente no carrinho
DELETE /carts/:product_id - remove completamente um item do carrinho
GET /carts - exibe o carrinho atual

Payload permitido para `/carts` e `/carts/add_item`:
```js
{
  "product_id": 345, // id do produto sendo adicionado
  "quantity": 2, // quantidade de produto a ser adicionado
}
```

Resposta padrão (retorna o carrinho atual):


```json
{
  "id": 789, // id do carrinho
  "products": [
    {
      "id": 645,
      "name": "Nome do produto",
      "quantity": 2,
      "unit_price": 1.99, // valor unitário do produto
      "total_price": 3.98, // valor total do produto
    },
    {
      "id": 646,
      "name": "Nome do produto 2",
      "quantity": 2,
      "unit_price": 1.99,
      "total_price": 3.98,
    },
  ],
  "total_price": 7.96 // valor total no carrinho
}
```

### Carrinhos abandonados
Um carrinho é considerado abandonado quando estiver sem interação (adição ou remoção de produtos) há mais de 3 horas. Se o carrinho está abandonado há mais de 7 dias, ele deve ser removido.

Gerenciamento feito com Jobs (Callback a partir do modelo de Cart):
1 - MarkCartAsAbandonedJob: a cada interação, faz o instanciamento de um job para validar se o carrinho foi abandonado após a terceira hora. Se já existe algum job para aquele carrinho, faz a remoção e reagenda.
2 - RemoveAbandonedCartJob: se o carrinho for marcado como abandonado, agenda um job para 7 dias e validar se ele pode ser removido.
Instanciação e controle dos jobs via callback.
3 - ClearAbandonedCartsCronJob: CRON JOB que roda uma vez por dia, às 02:59 (fim do dia) e checa se algum carrinho está inválido (ativo, porém com última interação maior que 3 horas ou 7 dias) e faz o tratamento adequado. Fallback para casos de falhas.

### Como executar o projeto

# Docker
Você precisa de ter um ambiente funcional do docker primeiro. Siga as instruções para seu sistema operacional:
- Windows: https://docs.docker.com/desktop/setup/install/windows-install/
- MacOS: https://docs.docker.com/desktop/setup/install/mac-install/
- Linux: https://docs.docker.com/desktop/setup/install/linux/

Você também precisa do `docker-compose` (https://docs.docker.com/compose/install/).

# Build e Instalação
Com o Docker instalado, navegue até a raiz do projeto e digite o comando abaixo para fazer a build dos containers.
```bash
docker-compose build
```

Após, rode os comandos abaixo para instalar os pacotes necessários e inicializar o banco de dados:
```bash
docker-compose run web bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
exit
```

Após esses comandos, você pode iniciar o projeto com:
```bash
docker-compose up
```

# Testes
Os testes estão em um container separado, e será instanciado apenas se você achar necessário. Os testes podem ser instanciados diretamente no container com:
```bash
docker-compose run --remove-orphans test
```
Se preferir deixar o container aberto e apenas rodar os testes manualmente:
```bash
docker-compose --profile=test run test bash
RAILS_ENV=test && bundle exec rspec
```

### Dependências
- ruby 3.3.1
- rails 7.1.3.2
- postgres 16
- redis 7.0.15
- sidekiq-cron
- factory_bot_rails
- faker
- database_cleaner

### Como enviar seu projeto
Salve seu código em um versionador de código (GitHub, GitLab, Bitbucket) e nos envie o link publico. Se achar necessário, informe no README as instruções para execução ou qualquer outra informação relevante para correção/entendimento da sua solução.
