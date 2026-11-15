# Dicionário de Dados — Distribuidora de Bebidas

Banco: `distribuidora_bebidas` · 14 tabelas · 85 colunas. Documento gerado a partir do `information_schema` do banco implantado.
Legenda: **PK** chave primária · **FK** chave estrangeira (com `ON UPDATE`/`ON DELETE`) · `UNIQUE` valor único · `NOT NULL` obrigatório · `CHECK` regra de domínio · `DEFAULT` valor padrão.

Consulte também o [DER](../img/der_distribuidora_bebidas.png) e o [relatório técnico](relatorio_tecnico.md).

#### Tabela `cidade`

Municípios atendidos ou onde há fornecedores/clientes. Isolar a UF aqui elimina a dependência transitiva cidade → UF.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_cidade` | INT | **PK**<br>AUTO_INCREMENT | Identificador da cidade |
| `nome` | VARCHAR(80) | NOT NULL | Nome do município |
| `uf` | CHAR(2) | NOT NULL<br>CHECK `char_length(uf) = 2` | Sigla do estado (2 letras) |

#### Tabela `categoria`

Classificação comercial das bebidas (cerveja, refrigerante, destilados etc.).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_categoria` | INT | **PK**<br>AUTO_INCREMENT | Identificador da categoria |
| `nome` | VARCHAR(50) | UNIQUE<br>NOT NULL | Nome da categoria |
| `descricao` | VARCHAR(200) |  | Descrição resumida da categoria |

#### Tabela `marca`

Marca comercial do produto e país de origem.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_marca` | INT | **PK**<br>AUTO_INCREMENT | Identificador da marca |
| `nome` | VARCHAR(60) | UNIQUE<br>NOT NULL | Nome da marca |
| `pais_origem` | VARCHAR(40) | NOT NULL<br>DEFAULT Brasil | País de origem da marca |

#### Tabela `fornecedor`

Indústrias, importadores e atacadistas que abastecem a distribuidora.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_fornecedor` | INT | **PK**<br>AUTO_INCREMENT | Identificador do fornecedor |
| `razao_social` | VARCHAR(120) | NOT NULL | Razão social |
| `cnpj` | CHAR(14) | UNIQUE<br>NOT NULL<br>CHECK `char_length(cnpj) = 14` | CNPJ (14 dígitos, sem máscara) |
| `email` | VARCHAR(120) | UNIQUE<br>NOT NULL | E-mail comercial |
| `telefone` | VARCHAR(15) | NOT NULL | Telefone com DDD |
| `id_cidade` | INT | **FK** → cidade(id_cidade) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Cidade sede do fornecedor |
| `ativo` | TINYINT(1) | NOT NULL<br>DEFAULT 1 | 1 = fornecedor ativo; 0 = inativo |

#### Tabela `produto`

Catálogo de bebidas comercializadas. Preços e quantidades referem-se à caixa/fardo.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_produto` | INT | **PK**<br>AUTO_INCREMENT | Identificador do produto |
| `sku` | VARCHAR(20) | UNIQUE<br>NOT NULL | Código interno único (SKU) |
| `nome` | VARCHAR(100) | NOT NULL | Nome comercial com volume/embalagem |
| `id_categoria` | INT | **FK** → categoria(id_categoria) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Categoria do produto |
| `id_marca` | INT | **FK** → marca(id_marca) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Marca do produto |
| `volume_ml` | INT | NOT NULL<br>CHECK `volume_ml > 0` | Volume de cada unidade, em mL |
| `unidades_por_caixa` | INT | NOT NULL<br>DEFAULT 12<br>CHECK `unidades_por_caixa > 0` | Quantidade de unidades em cada caixa/fardo |
| `teor_alcoolico` | DECIMAL(4,1) | NOT NULL<br>DEFAULT 0.0<br>CHECK `teor_alcoolico between 0 and 60` | Teor alcoólico em % (0 para não alcoólicas) |
| `preco_custo` | DECIMAL(10,2) | NOT NULL<br>CHECK `preco_custo > 0 and preco_venda >= preco_custo` | Custo atual da caixa para a distribuidora (R$) |
| `preco_venda` | DECIMAL(10,2) | NOT NULL<br>CHECK `preco_custo > 0 and preco_venda >= preco_custo` | Preço de tabela da caixa ao cliente (R$) |
| `ativo` | TINYINT(1) | NOT NULL<br>DEFAULT 1 | 1 = em linha; 0 = descontinuado |

#### Tabela `produto_fornecedor`

Associativa N:N entre produto e fornecedor: quem fornece o quê, a que preço e em quantos dias.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_produto` | INT | **PK**<br>**FK** → produto(id_produto) `ON UPDATE CASCADE ON DELETE CASCADE` | Produto fornecido |
| `id_fornecedor` | INT | **PK**<br>**FK** → fornecedor(id_fornecedor) `ON UPDATE CASCADE ON DELETE CASCADE` | Fornecedor do produto |
| `preco_compra` | DECIMAL(10,2) | NOT NULL<br>CHECK `preco_compra > 0` | Preço da caixa praticado pelo fornecedor (R$) |
| `prazo_entrega_dias` | INT | NOT NULL<br>DEFAULT 7<br>CHECK `prazo_entrega_dias between 1 and 60` | Prazo de entrega do fornecedor, em dias |

#### Tabela `estoque`

Posição de estoque de cada produto (relação 1:1 com produto), em caixas.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_produto` | INT | **PK**<br>**FK** → produto(id_produto) `ON UPDATE CASCADE ON DELETE CASCADE` | Produto (PK e FK: relação 1:1) |
| `quantidade_caixas` | INT | NOT NULL<br>DEFAULT 0<br>CHECK `quantidade_caixas >= 0` | Quantidade atual em caixas |
| `estoque_minimo` | INT | NOT NULL<br>DEFAULT 20<br>CHECK `estoque_minimo >= 0` | Nível mínimo antes de acionar reposição |
| `localizacao` | VARCHAR(20) | NOT NULL | Posição no armazém (corredor-prateleira) |
| `data_ultima_contagem` | DATE | NOT NULL | Data do último inventário |

#### Tabela `cliente`

Estabelecimentos comerciais compradores (bares, restaurantes, mercados, hotéis etc.).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_cliente` | INT | **PK**<br>AUTO_INCREMENT | Identificador do cliente |
| `razao_social` | VARCHAR(120) | NOT NULL | Razão social do estabelecimento |
| `cnpj` | CHAR(14) | UNIQUE<br>NOT NULL<br>CHECK `char_length(cnpj) = 14` | CNPJ (14 dígitos, sem máscara) |
| `email` | VARCHAR(120) | UNIQUE<br>NOT NULL | E-mail de contato |
| `telefone` | VARCHAR(15) | NOT NULL | Telefone com DDD |
| `tipo_cliente` | VARCHAR(15) | NOT NULL<br>CHECK `tipo_cliente in ('BAR','RESTAURANTE','SUPERMERCADO','PADARIA','LANCHONETE','HOTEL','EVENTOS','ADEGA','CONVENIENCIA')` | Segmento do cliente (BAR, RESTAURANTE, SUPERMERCADO, ...) |
| `id_cidade` | INT | **FK** → cidade(id_cidade) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Cidade do cliente |
| `limite_credito` | DECIMAL(10,2) | NOT NULL<br>DEFAULT 5000.00<br>CHECK `limite_credito >= 0` | Limite de crédito concedido (R$) |
| `data_cadastro` | DATE | NOT NULL<br>DEFAULT curdate() | Data de cadastro do cliente |
| `status` | CHAR(1) | NOT NULL<br>DEFAULT A<br>CHECK `status in ('A','I','B')` | A = Ativo; I = Inativo; B = Bloqueado |

#### Tabela `vendedor`

Equipe comercial responsável pelos pedidos e remunerada por comissão.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_vendedor` | INT | **PK**<br>AUTO_INCREMENT | Identificador do vendedor |
| `nome` | VARCHAR(100) | NOT NULL | Nome completo |
| `cpf` | CHAR(11) | UNIQUE<br>NOT NULL<br>CHECK `char_length(cpf) = 11` | CPF (11 dígitos, sem máscara) |
| `email` | VARCHAR(120) | UNIQUE<br>NOT NULL | E-mail corporativo |
| `telefone` | VARCHAR(15) | NOT NULL | Telefone com DDD |
| `comissao_pct` | DECIMAL(4,2) | NOT NULL<br>DEFAULT 2.00<br>CHECK `comissao_pct between 0 and 20` | Percentual de comissão sobre vendas (%) |
| `data_admissao` | DATE | NOT NULL | Data de admissão |
| `ativo` | TINYINT(1) | NOT NULL<br>DEFAULT 1 | 1 = em atividade; 0 = desligado |

#### Tabela `motorista`

Motoristas da frota própria que realizam as entregas.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_motorista` | INT | **PK**<br>AUTO_INCREMENT | Identificador do motorista |
| `nome` | VARCHAR(100) | NOT NULL | Nome completo |
| `cnh` | CHAR(11) | UNIQUE<br>NOT NULL | Número da CNH (11 dígitos) |
| `categoria_cnh` | CHAR(1) | NOT NULL<br>DEFAULT C<br>CHECK `categoria_cnh in ('B','C','D','E')` | Categoria da habilitação (B, C, D ou E) |
| `telefone` | VARCHAR(15) | NOT NULL | Telefone com DDD |
| `ativo` | TINYINT(1) | NOT NULL<br>DEFAULT 1 | 1 = em atividade; 0 = inativo |

#### Tabela `pedido`

Cabeçalho do pedido de venda. O valor total é derivado dos itens (view vw_pedido_total).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_pedido` | INT | **PK**<br>AUTO_INCREMENT | Identificador do pedido |
| `id_cliente` | INT | **FK** → cliente(id_cliente) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Cliente comprador |
| `id_vendedor` | INT | **FK** → vendedor(id_vendedor) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Vendedor responsável |
| `data_pedido` | DATE | NOT NULL | Data de emissão do pedido |
| `status` | VARCHAR(10) | NOT NULL<br>DEFAULT ABERTO<br>CHECK `status in ('ABERTO','FATURADO','ENTREGUE','CANCELADO')` | ABERTO, FATURADO, ENTREGUE ou CANCELADO |
| `observacao` | VARCHAR(200) |  | Observações livres do pedido |

#### Tabela `item_pedido`

Associativa N:N entre pedido e produto: itens vendidos, com preço praticado e desconto.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_pedido` | INT | **PK**<br>**FK** → pedido(id_pedido) `ON UPDATE CASCADE ON DELETE CASCADE` | Pedido ao qual o item pertence |
| `id_produto` | INT | **PK**<br>**FK** → produto(id_produto) `ON UPDATE CASCADE ON DELETE RESTRICT` | Produto vendido |
| `quantidade` | INT | NOT NULL<br>CHECK `quantidade > 0` | Quantidade vendida, em caixas |
| `preco_unitario` | DECIMAL(10,2) | NOT NULL<br>CHECK `preco_unitario > 0` | Preço da caixa praticado na data da venda (R$) |
| `desconto_pct` | DECIMAL(4,2) | NOT NULL<br>DEFAULT 0.00<br>CHECK `desconto_pct between 0 and 30` | Desconto concedido no item (%) |

#### Tabela `pagamento`

Parcelas de pagamento de um pedido (1:N com pedido).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_pagamento` | INT | **PK**<br>AUTO_INCREMENT | Identificador da parcela de pagamento |
| `id_pedido` | INT | **FK** → pedido(id_pedido) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Pedido pago |
| `forma_pagamento` | VARCHAR(15) | NOT NULL<br>CHECK `forma_pagamento in ('PIX','BOLETO','CARTAO_CREDITO','CARTAO_DEBITO','DINHEIRO')` | PIX, BOLETO, CARTAO_CREDITO, CARTAO_DEBITO ou DINHEIRO |
| `parcela` | INT | NOT NULL<br>DEFAULT 1<br>CHECK `parcela > 0` | Número da parcela dentro do pedido |
| `valor` | DECIMAL(12,2) | NOT NULL<br>CHECK `valor > 0` | Valor da parcela (R$) |
| `data_vencimento` | DATE | NOT NULL | Data de vencimento |
| `data_pagamento` | DATE | CHECK `status = 'PAGO' and data_pagamento is not null or status <> 'PAGO' and data_pagamento is null` | Data em que foi paga (nula se não paga) |
| `status` | VARCHAR(10) | NOT NULL<br>DEFAULT PENDENTE<br>CHECK `status in ('PENDENTE','PAGO','ATRASADO')`<br>CHECK `status = 'PAGO' and data_pagamento is not null or status <> 'PAGO' and data_pagamento is null` | PENDENTE, PAGO ou ATRASADO |

#### Tabela `entrega`

Entrega física de um pedido (1:1 com pedido), com motorista e datas.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_entrega` | INT | **PK**<br>AUTO_INCREMENT | Identificador da entrega |
| `id_pedido` | INT | **FK** → pedido(id_pedido) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>UNIQUE<br>NOT NULL | Pedido entregue (único: relação 1:1) |
| `id_motorista` | INT | **FK** → motorista(id_motorista) `ON UPDATE CASCADE ON DELETE RESTRICT`<br>NOT NULL | Motorista responsável |
| `data_prevista` | DATE | NOT NULL | Data prevista de entrega |
| `data_entrega` | DATE | CHECK `status = 'ENTREGUE' and data_entrega is not null or status <> 'ENTREGUE' and data_entrega is null` | Data efetiva (nula enquanto não entregue) |
| `status` | VARCHAR(10) | NOT NULL<br>DEFAULT AGENDADA<br>CHECK `status in ('AGENDADA','EM_ROTA','ENTREGUE','FALHA')`<br>CHECK `status = 'ENTREGUE' and data_entrega is not null or status <> 'ENTREGUE' and data_entrega is null` | AGENDADA, EM_ROTA, ENTREGUE ou FALHA |
