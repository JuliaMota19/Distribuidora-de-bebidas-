-- =====================================================================
--  PROJETO FINAL - BANCO DE DADOS | Engenharia da Computação - AFYA
--  Tema: Distribuidora de Bebidas
--  SGBD: MySQL 8.0.16+ (necessário para aplicar as restrições CHECK)
--  Arquivo: VERSÃO PARA SQL ONLINE (sem CREATE/DROP DATABASE nem USE)
--  Cole no editor do site e execute. Para recriar, apague as tabelas antes.
-- =====================================================================



-- =====================================================================
--  PARTE 1 - DDL (CREATE TABLE)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. cidade: evita a dependência transitiva cidade -> uf (3FN)
-- ---------------------------------------------------------------------
CREATE TABLE cidade (
    id_cidade   INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(80) NOT NULL,
    uf          CHAR(2)     NOT NULL,
    CONSTRAINT uq_cidade_nome_uf UNIQUE (nome, uf),
    CONSTRAINT ck_cidade_uf CHECK (CHAR_LENGTH(uf) = 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 2. categoria
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(50)  NOT NULL UNIQUE,
    descricao    VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 3. marca
-- ---------------------------------------------------------------------
CREATE TABLE marca (
    id_marca     INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(60) NOT NULL UNIQUE,
    pais_origem  VARCHAR(40) NOT NULL DEFAULT 'Brasil'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 4. fornecedor
-- ---------------------------------------------------------------------
CREATE TABLE fornecedor (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    razao_social  VARCHAR(120) NOT NULL,
    cnpj          CHAR(14)     NOT NULL UNIQUE,
    email         VARCHAR(120) NOT NULL UNIQUE,
    telefone      VARCHAR(15)  NOT NULL,
    id_cidade     INT          NOT NULL,
    ativo         BOOLEAN      NOT NULL DEFAULT 1,
    CONSTRAINT fk_fornecedor_cidade
        FOREIGN KEY (id_cidade) REFERENCES cidade(id_cidade)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_fornecedor_cnpj CHECK (CHAR_LENGTH(cnpj) = 14)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 5. produto (preços e quantidades referem-se à CAIXA/FARDO)
-- ---------------------------------------------------------------------
CREATE TABLE produto (
    id_produto         INT AUTO_INCREMENT PRIMARY KEY,
    sku                VARCHAR(20)   NOT NULL UNIQUE,
    nome               VARCHAR(100)  NOT NULL,
    id_categoria       INT           NOT NULL,
    id_marca           INT           NOT NULL,
    volume_ml          INT           NOT NULL,
    unidades_por_caixa INT           NOT NULL DEFAULT 12,
    teor_alcoolico     DECIMAL(4,1)  NOT NULL DEFAULT 0.0,
    preco_custo        DECIMAL(10,2) NOT NULL,
    preco_venda        DECIMAL(10,2) NOT NULL,
    ativo              BOOLEAN       NOT NULL DEFAULT 1,
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_produto_marca
        FOREIGN KEY (id_marca) REFERENCES marca(id_marca)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_produto_volume   CHECK (volume_ml > 0),
    CONSTRAINT ck_produto_unidades CHECK (unidades_por_caixa > 0),
    CONSTRAINT ck_produto_teor     CHECK (teor_alcoolico BETWEEN 0 AND 60),
    CONSTRAINT ck_produto_precos   CHECK (preco_custo > 0 AND preco_venda >= preco_custo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 6. produto_fornecedor  (N:N  produto <-> fornecedor)
-- ---------------------------------------------------------------------
CREATE TABLE produto_fornecedor (
    id_produto         INT           NOT NULL,
    id_fornecedor      INT           NOT NULL,
    preco_compra       DECIMAL(10,2) NOT NULL,
    prazo_entrega_dias INT           NOT NULL DEFAULT 7,
    PRIMARY KEY (id_produto, id_fornecedor),
    CONSTRAINT fk_pf_produto
        FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pf_fornecedor
        FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_pf_preco CHECK (preco_compra > 0),
    CONSTRAINT ck_pf_prazo CHECK (prazo_entrega_dias BETWEEN 1 AND 60)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 7. estoque  (1:1 com produto - dados voláteis separados do cadastro)
-- ---------------------------------------------------------------------
CREATE TABLE estoque (
    id_produto            INT         NOT NULL PRIMARY KEY,
    quantidade_caixas     INT         NOT NULL DEFAULT 0,
    estoque_minimo        INT         NOT NULL DEFAULT 20,
    localizacao           VARCHAR(20) NOT NULL,
    data_ultima_contagem  DATE        NOT NULL,
    CONSTRAINT fk_estoque_produto
        FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_estoque_qtd CHECK (quantidade_caixas >= 0),
    CONSTRAINT ck_estoque_min CHECK (estoque_minimo >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 8. cliente
--    tipo_cliente: BAR, RESTAURANTE, SUPERMERCADO, PADARIA, LANCHONETE,
--                  HOTEL, EVENTOS, ADEGA, CONVENIENCIA
--    status: A = Ativo | I = Inativo | B = Bloqueado (inadimplência)
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    razao_social    VARCHAR(120)  NOT NULL,
    cnpj            CHAR(14)      NOT NULL UNIQUE,
    email           VARCHAR(120)  NOT NULL UNIQUE,
    telefone        VARCHAR(15)   NOT NULL,
    tipo_cliente    VARCHAR(15)   NOT NULL,
    id_cidade       INT           NOT NULL,
    limite_credito  DECIMAL(10,2) NOT NULL DEFAULT 5000.00,
    data_cadastro   DATE          NOT NULL DEFAULT (CURRENT_DATE),
    status          CHAR(1)       NOT NULL DEFAULT 'A',
    CONSTRAINT fk_cliente_cidade
        FOREIGN KEY (id_cidade) REFERENCES cidade(id_cidade)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_cliente_cnpj   CHECK (CHAR_LENGTH(cnpj) = 14),
    CONSTRAINT ck_cliente_tipo   CHECK (tipo_cliente IN ('BAR','RESTAURANTE','SUPERMERCADO','PADARIA',
                                        'LANCHONETE','HOTEL','EVENTOS','ADEGA','CONVENIENCIA')),
    CONSTRAINT ck_cliente_limite CHECK (limite_credito >= 0),
    CONSTRAINT ck_cliente_status CHECK (status IN ('A','I','B'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 9. vendedor
-- ---------------------------------------------------------------------
CREATE TABLE vendedor (
    id_vendedor    INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    cpf            CHAR(11)     NOT NULL UNIQUE,
    email          VARCHAR(120) NOT NULL UNIQUE,
    telefone       VARCHAR(15)  NOT NULL,
    comissao_pct   DECIMAL(4,2) NOT NULL DEFAULT 2.00,
    data_admissao  DATE         NOT NULL,
    ativo          BOOLEAN      NOT NULL DEFAULT 1,
    CONSTRAINT ck_vendedor_cpf      CHECK (CHAR_LENGTH(cpf) = 11),
    CONSTRAINT ck_vendedor_comissao CHECK (comissao_pct BETWEEN 0 AND 20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 10. motorista
-- ---------------------------------------------------------------------
CREATE TABLE motorista (
    id_motorista   INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    cnh            CHAR(11)     NOT NULL UNIQUE,
    categoria_cnh  CHAR(1)      NOT NULL DEFAULT 'C',
    telefone       VARCHAR(15)  NOT NULL,
    ativo          BOOLEAN      NOT NULL DEFAULT 1,
    CONSTRAINT ck_motorista_cat CHECK (categoria_cnh IN ('B','C','D','E'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 11. pedido
--     status: ABERTO, FATURADO, ENTREGUE, CANCELADO
--     (o valor total NÃO é armazenado: é derivado de item_pedido,
--      ver view vw_pedido_total - evita redundância/anomalia de atualização)
-- ---------------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido     INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente    INT         NOT NULL,
    id_vendedor   INT         NOT NULL,
    data_pedido   DATE        NOT NULL,
    status        VARCHAR(10) NOT NULL DEFAULT 'ABERTO',
    observacao    VARCHAR(200),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pedido_vendedor
        FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pedido_status CHECK (status IN ('ABERTO','FATURADO','ENTREGUE','CANCELADO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 12. item_pedido  (N:N  pedido <-> produto)
--     preco_unitario é o preço PRATICADO na data da venda (histórico),
--     por isso pode diferir do preco_venda atual do produto.
-- ---------------------------------------------------------------------
CREATE TABLE item_pedido (
    id_pedido       INT           NOT NULL,
    id_produto      INT           NOT NULL,
    quantidade      INT           NOT NULL,
    preco_unitario  DECIMAL(10,2) NOT NULL,
    desconto_pct    DECIMAL(4,2)  NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_pedido, id_produto),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_produto
        FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_item_qtd      CHECK (quantidade > 0),
    CONSTRAINT ck_item_preco    CHECK (preco_unitario > 0),
    CONSTRAINT ck_item_desconto CHECK (desconto_pct BETWEEN 0 AND 30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 13. pagamento (1:N com pedido - um pedido pode ter várias parcelas)
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
    id_pagamento     INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido        INT           NOT NULL,
    forma_pagamento  VARCHAR(15)   NOT NULL,
    parcela          INT           NOT NULL DEFAULT 1,
    valor            DECIMAL(12,2) NOT NULL,
    data_vencimento  DATE          NOT NULL,
    data_pagamento   DATE,
    status           VARCHAR(10)   NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT uq_pagamento_parcela UNIQUE (id_pedido, parcela),
    CONSTRAINT fk_pagamento_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pagamento_forma  CHECK (forma_pagamento IN ('PIX','BOLETO','CARTAO_CREDITO',
                                          'CARTAO_DEBITO','DINHEIRO')),
    CONSTRAINT ck_pagamento_parcela CHECK (parcela > 0),
    CONSTRAINT ck_pagamento_valor  CHECK (valor > 0),
    CONSTRAINT ck_pagamento_status CHECK (status IN ('PENDENTE','PAGO','ATRASADO')),
    CONSTRAINT ck_pagamento_data   CHECK (
        (status = 'PAGO' AND data_pagamento IS NOT NULL) OR
        (status <> 'PAGO' AND data_pagamento IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 14. entrega (1:1 com pedido - um pedido gera no máximo uma entrega)
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    id_entrega      INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT         NOT NULL UNIQUE,
    id_motorista    INT         NOT NULL,
    data_prevista   DATE        NOT NULL,
    data_entrega    DATE,
    status          VARCHAR(10) NOT NULL DEFAULT 'AGENDADA',
    CONSTRAINT fk_entrega_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_motorista
        FOREIGN KEY (id_motorista) REFERENCES motorista(id_motorista)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_entrega_status CHECK (status IN ('AGENDADA','EM_ROTA','ENTREGUE','FALHA')),
    CONSTRAINT ck_entrega_data   CHECK (
        (status = 'ENTREGUE' AND data_entrega IS NOT NULL) OR
        (status <> 'ENTREGUE' AND data_entrega IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
--  PARTE 2 - ÍNDICES E VIEW AUXILIAR
-- =====================================================================
CREATE INDEX idx_pedido_data    ON pedido(data_pedido);
CREATE INDEX idx_produto_nome   ON produto(nome);
CREATE INDEX idx_pagamento_stat ON pagamento(status, data_vencimento);

-- Valor total de cada pedido (soma dos itens já com desconto aplicado)
CREATE VIEW vw_pedido_total AS
SELECT  ip.id_pedido,
        SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct / 100)) AS valor_total
FROM    item_pedido ip
GROUP BY ip.id_pedido;

-- =====================================================================
--  PARTE 3 - DML (POVOAMENTO) - dados fictícios, porém plausíveis
--  CPF/CNPJ gerados com dígitos verificadores válidos, mas inexistentes.
-- =====================================================================

-- ---------------------------------------------------------------------
-- cidade
-- ---------------------------------------------------------------------
INSERT INTO cidade (nome, uf) VALUES
  ('Belo Horizonte', 'MG'),
  ('Contagem', 'MG'),
  ('Betim', 'MG'),
  ('Sete Lagoas', 'MG'),
  ('Divinópolis', 'MG'),
  ('Montes Claros', 'MG'),
  ('Uberlândia', 'MG'),
  ('Juiz de Fora', 'MG'),
  ('Ipatinga', 'MG'),
  ('Governador Valadares', 'MG'),
  ('Pirapora', 'MG'),
  ('Curvelo', 'MG'),
  ('Três Marias', 'MG'),
  ('São Paulo', 'SP'),
  ('Rio de Janeiro', 'RJ');

-- ---------------------------------------------------------------------
-- categoria
-- ---------------------------------------------------------------------
INSERT INTO categoria (nome, descricao) VALUES
  ('Cerveja Pilsen', 'Cervejas claras tradicionais, em lata e garrafa'),
  ('Cerveja Premium', 'Cervejas premium e importadas, long neck e lata'),
  ('Cerveja Artesanal', 'Cervejas de produção artesanal e microcervejarias'),
  ('Cerveja sem Álcool', 'Cervejas com 0,0% de teor alcoólico'),
  ('Refrigerante', 'Refrigerantes de cola, guaraná e frutas'),
  ('Água Mineral', 'Águas minerais com e sem gás'),
  ('Suco e Néctar', 'Sucos prontos e néctares de frutas'),
  ('Energético', 'Bebidas energéticas'),
  ('Isotônico', 'Bebidas isotônicas para reposição esportiva'),
  ('Vinho Tinto', 'Vinhos tintos nacionais'),
  ('Vinho Branco', 'Vinhos brancos nacionais'),
  ('Espumante', 'Espumantes e vinhos frisantes'),
  ('Cachaça', 'Cachaças artesanais e industriais'),
  ('Whisky', 'Whiskies escoceses e americanos'),
  ('Vodka', 'Vodkas nacionais e importadas');

-- ---------------------------------------------------------------------
-- marca
-- ---------------------------------------------------------------------
INSERT INTO marca (nome, pais_origem) VALUES
  ('Skol', 'Brasil'),
  ('Brahma', 'Brasil'),
  ('Antarctica', 'Brasil'),
  ('Heineken', 'Países Baixos'),
  ('Budweiser', 'Estados Unidos'),
  ('Colorado', 'Brasil'),
  ('Coca-Cola', 'Estados Unidos'),
  ('Guaraná Antarctica', 'Brasil'),
  ('Minalba', 'Brasil'),
  ('Del Valle', 'Estados Unidos'),
  ('Red Bull', 'Áustria'),
  ('Gatorade', 'Estados Unidos'),
  ('Salton', 'Brasil'),
  ('Salinas', 'Brasil'),
  ('Johnnie Walker', 'Escócia'),
  ('Smirnoff', 'Reino Unido');

-- ---------------------------------------------------------------------
-- fornecedor
-- ---------------------------------------------------------------------
INSERT INTO fornecedor (razao_social, cnpj, email, telefone, id_cidade, ativo) VALUES
  ('Cervejaria Alto Paraopeba Ltda', '15881399000134', 'comercial@cervejaria-altoparaopeba.com.br', '(31) 3669-6891', 4, 1),
  ('Companhia Mineira de Cervejas S.A.', '98797309000159', 'vendas@cmcervejas.com.br', '(31) 3182-1814', 1, 1),
  ('Distribuidora Vale do Aço de Bebidas Ltda', '41707536000129', 'pedidos@valedoaco-bebidas.com.br', '(31) 3357-5696', 9, 1),
  ('Artesanal Serra do Espinhaço Cervejas Ltda', '56815188000180', 'contato@serradoespinhaco.com.br', '(31) 3399-4712', 1, 1),
  ('Engarrafadora Triângulo Mineiro Ltda', '72940557000113', 'comercial@engtriangulo.com.br', '(34) 3532-1485', 7, 1),
  ('Bebidas Sul de Minas Indústria e Comércio Ltda', '69871689000126', 'vendas@bebidassuldeminas.com.br', '(32) 3996-8045', 8, 1),
  ('Fonte Cristalina Águas Minerais Ltda', '68469788000113', 'comercial@fontecristalina.com.br', '(38) 3924-0415', 12, 1),
  ('Sucos e Néctares Mantiqueira S.A.', '93208196000195', 'pedidos@sucosmantiqueira.com.br', '(32) 3581-2333', 8, 1),
  ('Atacado Central de Bebidas Ltda', '73177848000164', 'vendas@atacadocentral.com.br', '(31) 3511-5040', 2, 1),
  ('Energia Bev Importação e Comércio Ltda', '88766344000157', 'comercial@energiabev.com.br', '(11) 3109-0542', 14, 1),
  ('Vinhos e Adegas do Sul Importadora Ltda', '29787534000191', 'contato@adegasdosul.com.br', '(11) 3809-7955', 14, 1),
  ('Vinícola Terra Alta Comércio Ltda', '78768045000106', 'vendas@vinicolaterraalta.com.br', '(21) 3568-1611', 15, 1),
  ('Engenho Serra Verde Cachaças Ltda', '78472671000142', 'comercial@engenhoserraverde.com.br', '(38) 3764-4365', 11, 1),
  ('Importadora Prime Spirits Ltda', '75136270000123', 'pedidos@primespirits.com.br', '(11) 3194-0003', 14, 1),
  ('Destilaria Rio das Velhas Ltda', '79819331000108', 'vendas@destilariariodasvelhas.com.br', '(38) 3735-0731', 12, 0);

-- ---------------------------------------------------------------------
-- produto
-- ---------------------------------------------------------------------
INSERT INTO produto (sku, nome, id_categoria, id_marca, volume_ml, unidades_por_caixa, teor_alcoolico, preco_custo, preco_venda, ativo) VALUES
  ('CER-001', 'Skol Pilsen Lata 350ml', 1, 1, 350, 12, 4.7, 33.00, 39.90, 1),
  ('CER-002', 'Brahma Chopp Lata 350ml', 1, 2, 350, 12, 4.8, 34.50, 41.90, 1),
  ('CER-003', 'Antarctica Pilsen Lata 350ml', 1, 3, 350, 12, 4.9, 33.80, 40.50, 1),
  ('CER-004', 'Heineken Long Neck 330ml', 2, 4, 330, 24, 5.0, 119.00, 145.00, 1),
  ('CER-005', 'Heineken Lata 350ml', 2, 4, 350, 12, 5.0, 55.00, 68.90, 1),
  ('CER-006', 'Budweiser Long Neck 330ml', 2, 5, 330, 24, 5.0, 98.00, 119.90, 1),
  ('CER-007', 'Colorado Appia Garrafa 600ml', 3, 6, 600, 12, 5.5, 180.00, 219.00, 1),
  ('CER-008', 'Colorado Ribeirão Lager Garrafa 600ml', 3, 6, 600, 12, 4.5, 150.00, 185.00, 0),
  ('CER-009', 'Heineken 0.0 Long Neck 330ml', 4, 4, 330, 24, 0.0, 96.00, 118.00, 1),
  ('REF-010', 'Coca-Cola PET 2L', 5, 7, 2000, 6, 0.0, 38.00, 47.50, 1),
  ('REF-011', 'Coca-Cola Lata 350ml', 5, 7, 350, 12, 0.0, 30.00, 38.90, 1),
  ('REF-012', 'Guaraná Antarctica PET 2L', 5, 8, 2000, 6, 0.0, 29.50, 37.90, 1),
  ('ÁGU-013', 'Minalba Água sem Gás 500ml', 6, 9, 500, 12, 0.0, 11.50, 16.90, 1),
  ('SUC-014', 'Del Valle Laranja 1L', 7, 10, 1000, 12, 0.0, 52.00, 64.90, 1),
  ('ENE-015', 'Red Bull Energy Drink 250ml', 8, 11, 250, 24, 0.0, 205.00, 249.00, 1),
  ('ISO-016', 'Gatorade Laranja 500ml', 9, 12, 500, 12, 0.0, 48.00, 62.90, 1),
  ('VIN-017', 'Salton Classic Merlot 750ml', 10, 13, 750, 6, 12.5, 120.00, 152.00, 1),
  ('VIN-018', 'Salton Classic Chardonnay 750ml', 11, 13, 750, 6, 12.0, 118.00, 149.00, 1),
  ('ESP-019', 'Salton Brut Espumante 750ml', 12, 13, 750, 6, 11.5, 170.00, 214.00, 1),
  ('CAC-020', 'Cachaça Salinas Tradicional 700ml', 13, 14, 700, 12, 38.0, 160.00, 204.00, 1),
  ('WHI-021', 'Johnnie Walker Red Label 1L', 14, 15, 1000, 12, 40.0, 900.00, 1090.00, 1),
  ('VOD-022', 'Smirnoff Vodka 998ml', 15, 16, 998, 12, 37.5, 395.00, 489.00, 1);

-- ---------------------------------------------------------------------
-- produto_fornecedor (N:N)
-- ---------------------------------------------------------------------
INSERT INTO produto_fornecedor (id_produto, id_fornecedor, preco_compra, prazo_entrega_dias) VALUES
  (1, 3, 33.03, 7),
  (2, 2, 34.69, 11),
  (2, 3, 34.47, 11),
  (3, 1, 34.45, 4),
  (4, 3, 122.04, 8),
  (5, 2, 55.90, 3),
  (6, 1, 102.74, 12),
  (6, 9, 99.44, 14),
  (7, 4, 184.63, 7),
  (8, 4, 151.92, 3),
  (9, 1, 96.07, 10),
  (9, 2, 96.43, 11),
  (10, 9, 39.21, 12),
  (11, 9, 29.77, 12),
  (12, 3, 30.54, 2),
  (13, 6, 11.96, 2),
  (13, 9, 11.49, 10),
  (14, 6, 52.06, 4),
  (15, 3, 210.60, 3),
  (15, 10, 208.45, 4),
  (16, 5, 48.41, 9),
  (17, 11, 120.29, 10),
  (17, 12, 122.85, 3),
  (18, 11, 123.82, 5),
  (19, 11, 178.76, 12),
  (20, 15, 164.50, 12),
  (21, 14, 913.17, 4),
  (22, 14, 394.08, 13);

-- ---------------------------------------------------------------------
-- estoque (1:1 com produto)
-- ---------------------------------------------------------------------
INSERT INTO estoque (id_produto, quantidade_caixas, estoque_minimo, localizacao, data_ultima_contagem) VALUES
  (1, 80, 40, 'A-02', '2026-06-01'),
  (2, 116, 40, 'A-03', '2026-06-01'),
  (3, 141, 40, 'A-04', '2026-06-01'),
  (4, 107, 30, 'A-05', '2026-06-01'),
  (5, 62, 30, 'A-06', '2026-06-01'),
  (6, 107, 30, 'A-07', '2026-06-01'),
  (7, 4, 15, 'A-08', '2026-06-01'),
  (8, 56, 15, 'A-09', '2026-06-01'),
  (9, 34, 12, 'A-10', '2026-06-01'),
  (10, 120, 30, 'B-11', '2026-06-01'),
  (11, 106, 30, 'B-12', '2026-06-01'),
  (12, 51, 30, 'B-01', '2026-06-01'),
  (13, 42, 25, 'B-02', '2026-06-01'),
  (14, 36, 15, 'B-03', '2026-06-01'),
  (15, 1, 8, 'B-04', '2026-06-01'),
  (16, 44, 12, 'C-05', '2026-06-01'),
  (17, 2, 8, 'C-06', '2026-06-01'),
  (18, 16, 8, 'C-07', '2026-06-01'),
  (19, 21, 6, 'C-08', '2026-06-01'),
  (20, 16, 10, 'D-09', '2026-06-01'),
  (21, 15, 5, 'D-10', '2026-06-01'),
  (22, 5, 6, 'D-11', '2026-06-01');

-- ---------------------------------------------------------------------
-- cliente
-- ---------------------------------------------------------------------
INSERT INTO cliente (razao_social, cnpj, email, telefone, tipo_cliente, id_cidade, limite_credito, data_cadastro, status) VALUES
  ('Bar do Zé Mineiro', '21854914000190', 'contato@bardozemineiro.com.br', '(31) 99908-5154', 'BAR', 1, 8000.00, '2022-03-14', 'A'),
  ('Restaurante Sabor de Minas Ltda', '24410646000105', 'contato@sabordeminas.com.br', '(31) 99977-0252', 'RESTAURANTE', 1, 15000.00, '2021-08-02', 'A'),
  ('Supermercado Bom Preço Ltda', '01304118000176', 'contato@bompreco.com.br', '(31) 99180-5739', 'SUPERMERCADO', 2, 40000.00, '2020-05-19', 'A'),
  ('Padaria Pão Quente Ltda', '57990659000150', 'contato@paoquente.com.br', '(31) 98441-9733', 'PADARIA', 3, 6000.00, '2023-01-10', 'A'),
  ('Boteco Esquina da Praça Ltda', '76158464000192', 'contato@esquinadapraca.com.br', '(31) 99939-5837', 'BAR', 4, 5000.00, '2022-11-23', 'A'),
  ('Churrascaria Fogo Mineiro Ltda', '06045414000113', 'contato@fogomineiro.com.br', '(38) 99572-6826', 'RESTAURANTE', 6, 20000.00, '2021-02-15', 'A'),
  ('Hotel Serra Verde S.A.', '59085380000157', 'contato@hotelserraverde.com.br', '(31) 99477-1844', 'HOTEL', 9, 30000.00, '2020-09-30', 'A'),
  ('Empório Casa Grande Ltda', '29110285000103', 'contato@emporiocasagrande.com.br', '(38) 99222-4951', 'SUPERMERCADO', 12, 25000.00, '2021-10-11', 'A'),
  ('Bar e Petiscaria do Cais Ltda', '06925666000137', 'contato@petiscariadocais.com.br', '(38) 98490-6897', 'BAR', 11, 7000.00, '2022-06-05', 'A'),
  ('Celebrare Eventos e Buffet Ltda', '32280886000160', 'contato@celebrareeventos.com.br', '(31) 99820-4177', 'EVENTOS', 1, 35000.00, '2021-04-27', 'A'),
  ('Pizzaria Forno a Lenha Ltda', '23004876000101', 'contato@fornoalenha.com.br', '(34) 98540-5156', 'RESTAURANTE', 7, 12000.00, '2022-09-12', 'A'),
  ('Adega Premium Vinhos e Cia Ltda', '29128084000125', 'contato@adegapremium.com.br', '(31) 98697-8527', 'ADEGA', 1, 18000.00, '2021-12-03', 'A'),
  ('Pousada Recanto das Águas Ltda', '50037038000107', 'contato@recantodasaguas.com.br', '(38) 99765-2471', 'HOTEL', 13, 10000.00, '2023-05-22', 'A'),
  ('Salão de Festas Villa Jardim Ltda', '65384535000159', 'contato@villajardim.com.br', '(31) 98735-7524', 'EVENTOS', 2, 22000.00, '2022-10-08', 'A'),
  ('Conveniência Quick Stop Ltda', '78794326000125', 'contato@quickstop.com.br', '(31) 98314-7943', 'CONVENIENCIA', 1, 9000.00, '2023-11-20', 'B'),
  ('Cantina Bella Napoli Ltda', '05860214000151', 'contato@bellanapoli.com.br', '(31) 98763-8957', 'RESTAURANTE', 1, 14000.00, '2022-04-04', 'A'),
  ('Padaria Trigo de Ouro Ltda', '42108394000146', 'contato@trigodeouro.com.br', '(38) 99172-0731', 'PADARIA', 6, 5000.00, '2024-02-19', 'A'),
  ('Supermercado Econômico Ltda', '66882811000171', 'contato@economico.com.br', '(34) 98290-6376', 'SUPERMERCADO', 7, 30000.00, '2024-03-11', 'I');

-- ---------------------------------------------------------------------
-- vendedor
-- ---------------------------------------------------------------------
INSERT INTO vendedor (nome, cpf, email, telefone, comissao_pct, data_admissao, ativo) VALUES
  ('Carlos Eduardo Menezes', '58440932405', 'carlos.menezes@distribuidora.com.br', '(31) 98604-8866', 3.00, '2019-02-04', 1),
  ('Fernanda Lima Rocha', '45263097611', 'fernanda.rocha@distribuidora.com.br', '(31) 98728-8804', 2.50, '2019-08-19', 1),
  ('Rafael Augusto Teixeira', '28025822087', 'rafael.teixeira@distribuidora.com.br', '(31) 99816-1911', 2.50, '2020-01-13', 1),
  ('Juliana Prado Almeida', '80515438235', 'juliana.almeida@distribuidora.com.br', '(31) 99227-9994', 3.00, '2020-06-01', 1),
  ('Marcos Vinícius Souza', '32157116486', 'marcos.souza@distribuidora.com.br', '(31) 99263-4939', 2.00, '2020-11-09', 1),
  ('Patrícia Nogueira Dias', '15771883573', 'patricia.dias@distribuidora.com.br', '(31) 99399-7470', 2.50, '2021-03-22', 1),
  ('Thiago Henrique Barbosa', '95111744363', 'thiago.barbosa@distribuidora.com.br', '(31) 98344-5324', 2.00, '2021-07-05', 1),
  ('Camila Ferreira Duarte', '68855765221', 'camila.duarte@distribuidora.com.br', '(31) 98402-7585', 3.50, '2021-10-18', 1),
  ('Bruno Cavalcanti Reis', '35569632727', 'bruno.reis@distribuidora.com.br', '(31) 99521-9282', 2.00, '2022-02-14', 1),
  ('Aline Martins Costa', '26451547433', 'aline.costa@distribuidora.com.br', '(31) 98297-8931', 2.50, '2022-05-30', 1),
  ('Diego Fernandes Lopes', '43528144904', 'diego.lopes@distribuidora.com.br', '(31) 98938-6573', 2.00, '2022-09-26', 1),
  ('Larissa Gomes Pinheiro', '60856517836', 'larissa.pinheiro@distribuidora.com.br', '(31) 99058-3439', 2.50, '2023-01-16', 1),
  ('Felipe Araújo Santana', '65506204817', 'felipe.santana@distribuidora.com.br', '(31) 99437-4131', 2.00, '2023-04-03', 1),
  ('Vanessa Ribeiro Moura', '25996775050', 'vanessa.moura@distribuidora.com.br', '(31) 98076-3602', 2.00, '2023-08-21', 1),
  ('Renata Carvalho Batista', '14503784986', 'renata.batista@distribuidora.com.br', '(31) 99290-6052', 1.50, '2024-06-10', 0);

-- ---------------------------------------------------------------------
-- motorista
-- ---------------------------------------------------------------------
INSERT INTO motorista (nome, cnh, categoria_cnh, telefone, ativo) VALUES
  ('José Antônio Pereira', '18380125373', 'E', '(31) 99241-2798', 1),
  ('Sebastião Rodrigues Filho', '41968982104', 'D', '(31) 99923-6873', 1),
  ('Adilson Moreira Lima', '02883755559', 'E', '(31) 98982-4183', 1),
  ('Wagner Santos Oliveira', '75407207547', 'C', '(31) 98407-6021', 1),
  ('Edmilson Cardoso', '48643906188', 'D', '(31) 99568-4892', 1),
  ('Luciano Barros Neves', '79188957555', 'E', '(31) 98371-1279', 1),
  ('Márcio Gonçalves', '82488619307', 'C', '(31) 98493-3435', 1),
  ('Josué Ferreira Alves', '68828347285', 'C', '(31) 98744-6422', 1),
  ('Ronaldo Batista Cruz', '89832982229', 'D', '(31) 98125-0565', 1),
  ('Paulo César Andrade', '44224852722', 'E', '(31) 99419-0878', 1),
  ('Cláudio Fonseca', '22697804385', 'C', '(31) 99818-8892', 1),
  ('Anderson Silva Matos', '17625280700', 'D', '(31) 98193-5783', 1),
  ('Valdir Campos', '94502831663', 'C', '(31) 99706-2796', 1),
  ('Rogério Tavares', '33735286675', 'E', '(31) 99443-3427', 1),
  ('Everton Lacerda', '47897133115', 'C', '(31) 99463-2589', 1);

-- ---------------------------------------------------------------------
-- pedido
-- ---------------------------------------------------------------------
INSERT INTO pedido (id_cliente, id_vendedor, data_pedido, status, observacao) VALUES
  (11, 13, '2026-01-07', 'ENTREGUE', 'Entregar pela manhã'),
  (15, 10, '2026-01-17', 'ENTREGUE', NULL),
  (14, 13, '2026-01-26', 'ENTREGUE', NULL),
  (1, 12, '2026-02-06', 'ENTREGUE', NULL),
  (12, 8, '2026-02-13', 'CANCELADO', NULL),
  (10, 1, '2026-02-24', 'ENTREGUE', 'Cliente solicita nota fiscal antecipada'),
  (16, 13, '2026-03-02', 'ENTREGUE', 'Entrega no portão lateral'),
  (7, 8, '2026-03-12', 'ENTREGUE', NULL),
  (8, 1, '2026-03-23', 'ENTREGUE', 'Entregar pela manhã'),
  (6, 2, '2026-04-01', 'ENTREGUE', NULL),
  (4, 8, '2026-04-10', 'ENTREGUE', NULL),
  (9, 14, '2026-04-20', 'ENTREGUE', NULL),
  (3, 11, '2026-04-27', 'CANCELADO', 'Entregar pela manhã'),
  (13, 6, '2026-05-08', 'ENTREGUE', NULL),
  (2, 5, '2026-05-18', 'ENTREGUE', NULL),
  (5, 13, '2026-05-25', 'ENTREGUE', 'Reposição de estoque para fim de semana'),
  (16, 5, '2026-06-03', 'ENTREGUE', 'Entrega no portão lateral'),
  (15, 9, '2026-06-12', 'ENTREGUE', 'Entrega no portão lateral'),
  (11, 3, '2026-06-15', 'FATURADO', 'Reposição de estoque para fim de semana'),
  (13, 9, '2026-06-18', 'FATURADO', NULL),
  (3, 4, '2026-06-22', 'ABERTO', NULL),
  (3, 7, '2026-06-24', 'ABERTO', NULL);

-- ---------------------------------------------------------------------
-- item_pedido (N:N)
-- ---------------------------------------------------------------------
INSERT INTO item_pedido (id_pedido, id_produto, quantidade, preco_unitario, desconto_pct) VALUES
  (1, 4, 19, 139.20, 10.00),
  (1, 7, 2, 210.24, 10.00),
  (2, 10, 7, 45.60, 0.00),
  (2, 11, 13, 37.34, 0.00),
  (2, 13, 5, 16.22, 0.00),
  (2, 21, 1, 1046.40, 2.50),
  (3, 12, 13, 36.38, 5.00),
  (3, 14, 4, 62.30, 0.00),
  (4, 1, 20, 38.30, 5.00),
  (4, 2, 16, 40.22, 2.50),
  (4, 3, 17, 38.88, 10.00),
  (4, 14, 3, 62.30, 0.00),
  (5, 3, 38, 38.88, 0.00),
  (5, 10, 11, 45.60, 10.00),
  (5, 12, 16, 36.38, 10.00),
  (5, 13, 28, 16.22, 5.00),
  (6, 1, 18, 38.30, 5.00),
  (6, 4, 5, 139.20, 5.00),
  (6, 20, 2, 195.84, 0.00),
  (7, 1, 15, 38.30, 5.00),
  (7, 3, 22, 38.88, 0.00),
  (7, 12, 5, 36.38, 0.00),
  (7, 21, 2, 1046.40, 0.00),
  (8, 4, 25, 139.20, 2.50),
  (8, 16, 10, 60.38, 5.00),
  (9, 1, 18, 39.90, 0.00),
  (9, 2, 23, 41.90, 5.00),
  (10, 1, 27, 39.90, 0.00),
  (10, 9, 10, 118.00, 2.50),
  (10, 10, 17, 47.50, 0.00),
  (11, 2, 22, 41.90, 5.00),
  (11, 4, 23, 145.00, 0.00),
  (11, 10, 17, 47.50, 0.00),
  (12, 2, 10, 41.90, 5.00),
  (12, 10, 18, 47.50, 5.00),
  (12, 13, 18, 16.90, 0.00),
  (13, 1, 16, 39.90, 0.00),
  (13, 16, 10, 62.90, 0.00),
  (13, 20, 1, 204.00, 0.00),
  (14, 3, 37, 40.50, 5.00),
  (14, 7, 8, 219.00, 0.00),
  (14, 10, 5, 47.50, 0.00),
  (14, 20, 2, 204.00, 0.00),
  (15, 4, 17, 145.00, 5.00),
  (15, 10, 6, 47.50, 0.00),
  (15, 11, 6, 38.90, 0.00),
  (15, 20, 2, 204.00, 10.00),
  (16, 3, 23, 40.50, 10.00),
  (16, 5, 13, 68.90, 10.00),
  (16, 12, 8, 37.90, 0.00),
  (17, 2, 11, 41.90, 0.00),
  (17, 11, 15, 38.90, 0.00),
  (17, 14, 7, 64.90, 5.00),
  (18, 3, 37, 40.50, 0.00),
  (18, 4, 4, 145.00, 5.00),
  (18, 18, 5, 149.00, 10.00),
  (19, 10, 20, 47.50, 0.00),
  (19, 11, 16, 38.90, 0.00),
  (19, 12, 20, 37.90, 10.00),
  (19, 13, 21, 16.90, 0.00),
  (20, 5, 14, 68.90, 10.00),
  (20, 11, 10, 38.90, 0.00),
  (21, 6, 9, 119.90, 0.00),
  (21, 7, 1, 219.00, 0.00),
  (21, 11, 20, 38.90, 0.00),
  (21, 13, 8, 16.90, 0.00),
  (22, 5, 13, 68.90, 0.00),
  (22, 10, 3, 47.50, 0.00),
  (22, 11, 6, 38.90, 0.00),
  (22, 22, 1, 489.00, 10.00);

-- ---------------------------------------------------------------------
-- pagamento
-- ---------------------------------------------------------------------
INSERT INTO pagamento (id_pedido, forma_pagamento, parcela, valor, data_vencimento, data_pagamento, status) VALUES
  (1, 'BOLETO', 1, 1379.37, '2026-02-06', NULL, 'ATRASADO'),
  (1, 'BOLETO', 2, 1379.38, '2026-03-08', NULL, 'ATRASADO'),
  (2, 'BOLETO', 1, 952.98, '2026-02-16', NULL, 'ATRASADO'),
  (2, 'BOLETO', 2, 952.98, '2026-03-18', '2026-03-19', 'PAGO'),
  (3, 'BOLETO', 1, 698.49, '2026-02-23', '2026-02-25', 'PAGO'),
  (4, 'PIX', 1, 2136.90, '2026-02-07', '2026-02-07', 'PAGO'),
  (6, 'PIX', 1, 1707.81, '2026-02-25', '2026-02-25', 'PAGO'),
  (7, 'DINHEIRO', 1, 3675.84, '2026-03-03', '2026-03-03', 'PAGO'),
  (8, 'DINHEIRO', 1, 3966.61, '2026-03-13', '2026-03-13', 'PAGO'),
  (9, 'PIX', 1, 1633.72, '2026-03-24', '2026-03-24', 'PAGO'),
  (10, 'BOLETO', 1, 1517.65, '2026-05-01', '2026-05-01', 'PAGO'),
  (10, 'BOLETO', 2, 1517.65, '2026-05-31', '2026-06-02', 'PAGO'),
  (11, 'BOLETO', 1, 2509.10, '2026-05-10', '2026-05-10', 'PAGO'),
  (11, 'BOLETO', 2, 2509.11, '2026-06-09', '2026-06-09', 'PAGO'),
  (12, 'CARTAO_CREDITO', 1, 1514.50, '2026-05-20', '2026-05-21', 'PAGO'),
  (14, 'PIX', 1, 3821.08, '2026-05-09', '2026-05-09', 'PAGO'),
  (15, 'BOLETO', 1, 1613.67, '2026-06-17', '2026-06-17', 'PAGO'),
  (15, 'BOLETO', 2, 1613.68, '2026-07-17', NULL, 'PENDENTE'),
  (16, 'BOLETO', 1, 973.84, '2026-06-24', '2026-06-25', 'PAGO'),
  (16, 'BOLETO', 2, 973.84, '2026-07-24', NULL, 'PENDENTE'),
  (17, 'PIX', 1, 1475.99, '2026-06-04', '2026-06-04', 'PAGO'),
  (18, 'BOLETO', 1, 1360.00, '2026-07-12', NULL, 'PENDENTE'),
  (18, 'BOLETO', 2, 1360.00, '2026-08-11', NULL, 'PENDENTE'),
  (19, 'BOLETO', 1, 1304.75, '2026-07-15', NULL, 'PENDENTE'),
  (19, 'BOLETO', 2, 1304.75, '2026-08-14', NULL, 'PENDENTE'),
  (20, 'PIX', 1, 1257.14, '2026-06-19', '2026-06-19', 'PAGO');

-- ---------------------------------------------------------------------
-- entrega (1:1 com pedido)
-- ---------------------------------------------------------------------
INSERT INTO entrega (id_pedido, id_motorista, data_prevista, data_entrega, status) VALUES
  (1, 2, '2026-01-08', '2026-01-10', 'ENTREGUE'),
  (2, 1, '2026-01-18', '2026-01-21', 'ENTREGUE'),
  (3, 6, '2026-01-28', '2026-01-29', 'ENTREGUE'),
  (4, 8, '2026-02-09', '2026-02-11', 'ENTREGUE'),
  (6, 13, '2026-02-25', '2026-02-25', 'ENTREGUE'),
  (7, 4, '2026-03-03', '2026-03-03', 'ENTREGUE'),
  (8, 11, '2026-03-14', '2026-03-16', 'ENTREGUE'),
  (9, 15, '2026-03-26', '2026-03-27', 'ENTREGUE'),
  (10, 9, '2026-04-04', '2026-04-04', 'ENTREGUE'),
  (11, 14, '2026-04-12', '2026-04-14', 'ENTREGUE'),
  (12, 2, '2026-04-22', '2026-04-22', 'ENTREGUE'),
  (14, 3, '2026-05-10', '2026-05-12', 'ENTREGUE'),
  (15, 5, '2026-05-21', '2026-05-23', 'ENTREGUE'),
  (16, 4, '2026-05-26', '2026-05-26', 'ENTREGUE'),
  (17, 10, '2026-06-05', '2026-06-06', 'ENTREGUE'),
  (18, 14, '2026-06-14', '2026-06-16', 'ENTREGUE'),
  (19, 14, '2026-06-17', NULL, 'AGENDADA'),
  (20, 6, '2026-06-21', NULL, 'EM_ROTA');
