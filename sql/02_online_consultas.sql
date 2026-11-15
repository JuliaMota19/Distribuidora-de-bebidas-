-- =====================================================================
--  PROJETO FINAL - BANCO DE DADOS | Distribuidora de Bebidas
--  Script de consultas (19 consultas)
--  Execute antes: 01_online_criacao_e_povoamento.sql
--  VERSÃO PARA SQL ONLINE: cole e execute UMA consulta por vez.
--  Convenção: valores monetários em R$; quantidades em caixas/fardos.
--  Data de referência dos dados: 25/06/2026.
-- =====================================================================

-- =====================================================================
--  BLOCO A - CONSULTAS SIMPLES (sem JOIN)
-- =====================================================================

-- [Q01] Os 10 produtos ativos mais caros do catálogo.
-- Recursos: WHERE, ORDER BY, LIMIT
SELECT sku, nome, preco_venda
FROM   produto
WHERE  ativo = 1
ORDER  BY preco_venda DESC
LIMIT  10;

-- [Q02] Produtos vendidos em lata, em ordem alfabética.
-- Recursos: LIKE, ORDER BY
SELECT id_produto, nome, volume_ml, unidades_por_caixa, preco_venda
FROM   produto
WHERE  nome LIKE '%Lata%'
ORDER  BY nome;

-- [Q03] Pedidos faturados ou entregues em março de 2026.
-- Recursos: BETWEEN, IN, ORDER BY
SELECT id_pedido, id_cliente, id_vendedor, data_pedido, status
FROM   pedido
WHERE  data_pedido BETWEEN '2026-03-01' AND '2026-03-31'
  AND  status IN ('FATURADO', 'ENTREGUE')
ORDER  BY data_pedido, id_pedido;

-- [Q04] Bares e restaurantes ativos, em ordem alfabética.
-- Recursos: IN, AND, ORDER BY
SELECT id_cliente, razao_social, tipo_cliente, limite_credito
FROM   cliente
WHERE  tipo_cliente IN ('BAR', 'RESTAURANTE')
  AND  status = 'A'
ORDER  BY razao_social;

-- [Q05] Formas de pagamento efetivamente utilizadas.
-- Recursos: DISTINCT, ORDER BY
SELECT DISTINCT forma_pagamento
FROM   pagamento
ORDER  BY forma_pagamento;

-- [Q06] Vendedores admitidos até 2021 com comissão de 2,5% ou mais.
-- Recursos: WHERE composto, ORDER BY
SELECT nome, comissao_pct, data_admissao
FROM   vendedor
WHERE  data_admissao < '2022-01-01'
  AND  comissao_pct >= 2.5
ORDER  BY comissao_pct DESC, data_admissao;

-- =====================================================================
--  BLOCO B - CONSULTAS COM JOIN, GROUP BY, HAVING E FUNÇÕES DE AGREGAÇÃO
-- =====================================================================

-- [Q07] Resumo do catálogo por categoria: quantidade de produtos e preços.
-- Recursos: INNER JOIN (2 tabelas), COUNT, AVG, MIN, MAX, GROUP BY
SELECT c.nome                      AS categoria,
       COUNT(p.id_produto)         AS qtd_produtos,
       ROUND(AVG(p.preco_venda),2) AS preco_medio,
       MIN(p.preco_venda)          AS menor_preco,
       MAX(p.preco_venda)          AS maior_preco
FROM   categoria c
JOIN   produto   p ON p.id_categoria = c.id_categoria
GROUP  BY c.id_categoria, c.nome
ORDER  BY qtd_produtos DESC, categoria;

-- [Q08] Cidades que possuem 2 ou mais clientes cadastrados.
-- Recursos: INNER JOIN (2 tabelas), COUNT, GROUP BY, HAVING
SELECT ci.nome AS cidade, ci.uf, COUNT(*) AS qtd_clientes
FROM   cidade  ci
JOIN   cliente cl ON cl.id_cidade = ci.id_cidade
GROUP  BY ci.id_cidade, ci.nome, ci.uf
HAVING COUNT(*) >= 2
ORDER  BY qtd_clientes DESC, cidade;

-- [Q09] Faturamento por cliente (pedidos não cancelados) acima de R$ 4.000.
-- Recursos: JOIN (3 tabelas), SUM com expressão, GROUP BY, HAVING
SELECT cl.razao_social,
       COUNT(DISTINCT pe.id_pedido) AS qtd_pedidos,
       ROUND(SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100)), 2) AS faturamento
FROM   cliente     cl
JOIN   pedido      pe ON pe.id_cliente = cl.id_cliente
JOIN   item_pedido ip ON ip.id_pedido  = pe.id_pedido
WHERE  pe.status <> 'CANCELADO'
GROUP  BY cl.id_cliente, cl.razao_social
HAVING faturamento > 4000
ORDER  BY faturamento DESC;

-- [Q10] Top 10 produtos mais vendidos (em caixas), com categoria e marca.
-- Recursos: JOIN (5 tabelas), SUM, GROUP BY, ORDER BY, LIMIT
SELECT pr.nome   AS produto,
       ca.nome   AS categoria,
       ma.nome   AS marca,
       SUM(ip.quantidade) AS caixas_vendidas
FROM   item_pedido ip
JOIN   pedido      pe ON pe.id_pedido    = ip.id_pedido
JOIN   produto     pr ON pr.id_produto   = ip.id_produto
JOIN   categoria   ca ON ca.id_categoria = pr.id_categoria
JOIN   marca       ma ON ma.id_marca     = pr.id_marca
WHERE  pe.status <> 'CANCELADO'
GROUP  BY pr.id_produto, pr.nome, ca.nome, ma.nome
ORDER  BY caixas_vendidas DESC
LIMIT  10;

-- [Q11] Ranking de vendedores com a comissão devida sobre pedidos entregues.
-- Recursos: JOIN (3 tabelas), SUM, expressão aritmética, GROUP BY
SELECT ve.nome AS vendedor,
       ve.comissao_pct,
       COUNT(DISTINCT pe.id_pedido) AS pedidos_entregues,
       ROUND(SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100)), 2) AS vendas,
       ROUND(SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100)) * ve.comissao_pct/100, 2) AS comissao_devida
FROM   vendedor    ve
JOIN   pedido      pe ON pe.id_vendedor = ve.id_vendedor
JOIN   item_pedido ip ON ip.id_pedido   = pe.id_pedido
WHERE  pe.status = 'ENTREGUE'
GROUP  BY ve.id_vendedor, ve.nome, ve.comissao_pct
ORDER  BY vendas DESC;

-- [Q12] Margem de lucro estimada por marca (receita x custo atual), margem > 18%.
-- Recursos: JOIN (4 tabelas), SUM, GROUP BY, HAVING com alias calculado
SELECT ma.nome AS marca,
       SUM(ip.quantidade)                                                  AS caixas,
       ROUND(SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100)), 2) AS receita,
       ROUND(SUM(ip.quantidade * pr.preco_custo), 2)                       AS custo,
       ROUND(SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100))
           - SUM(ip.quantidade * pr.preco_custo), 2)                       AS lucro,
       ROUND((SUM(ip.quantidade * ip.preco_unitario * (1 - ip.desconto_pct/100))
            / SUM(ip.quantidade * pr.preco_custo) - 1) * 100, 1)           AS margem_pct
FROM   item_pedido ip
JOIN   pedido  pe ON pe.id_pedido  = ip.id_pedido
JOIN   produto pr ON pr.id_produto = ip.id_produto
JOIN   marca   ma ON ma.id_marca   = pr.id_marca
WHERE  pe.status <> 'CANCELADO'
GROUP  BY ma.id_marca, ma.nome
HAVING margem_pct > 18
ORDER  BY lucro DESC;

-- [Q13] Produtos com estoque abaixo do mínimo e quantidade a repor.
-- Recursos: JOIN (3 tabelas, incluindo a relação 1:1), expressão, ORDER BY
SELECT pr.nome AS produto,
       ca.nome AS categoria,
       es.quantidade_caixas AS em_estoque,
       es.estoque_minimo,
       es.estoque_minimo - es.quantidade_caixas AS falta_para_o_minimo,
       es.localizacao
FROM   estoque   es
JOIN   produto   pr ON pr.id_produto   = es.id_produto
JOIN   categoria ca ON ca.id_categoria = pr.id_categoria
WHERE  es.quantidade_caixas < es.estoque_minimo
ORDER  BY falta_para_o_minimo DESC;

-- [Q14] Fornecedores: quantidade de produtos que fornecem e prazo médio de entrega.
-- Recursos: JOIN (3 tabelas, relação N:N), COUNT, AVG, GROUP BY, HAVING
SELECT fo.razao_social AS fornecedor,
       ci.nome         AS cidade,
       COUNT(*)        AS produtos_fornecidos,
       ROUND(AVG(pf.prazo_entrega_dias), 1) AS prazo_medio_dias
FROM   fornecedor         fo
JOIN   produto_fornecedor pf ON pf.id_fornecedor = fo.id_fornecedor
JOIN   cidade             ci ON ci.id_cidade     = fo.id_cidade
GROUP  BY fo.id_fornecedor, fo.razao_social, ci.nome
HAVING COUNT(*) >= 3
ORDER  BY produtos_fornecidos DESC, prazo_medio_dias;

-- =====================================================================
--  BLOCO C - CONSULTAS BÔNUS (LEFT JOIN, SUBCONSULTAS E OUTRAS)
-- =====================================================================

-- [Q15] Produtos que nunca foram vendidos.
-- Recursos: LEFT JOIN com IS NULL (anti-join)
SELECT pr.id_produto, pr.nome, pr.preco_venda, es.quantidade_caixas AS em_estoque
FROM   produto     pr
LEFT   JOIN item_pedido ip ON ip.id_produto = pr.id_produto
JOIN   estoque     es ON es.id_produto = pr.id_produto
WHERE  ip.id_pedido IS NULL
ORDER  BY pr.nome;

-- [Q16] Clientes cadastrados que nunca fizeram pedido (oportunidade comercial).
-- Recursos: LEFT JOIN com IS NULL, JOIN com cidade
SELECT cl.razao_social, cl.tipo_cliente, ci.nome AS cidade, cl.status, cl.data_cadastro
FROM   cliente cl
JOIN   cidade  ci ON ci.id_cidade  = cl.id_cidade
LEFT   JOIN pedido pe ON pe.id_cliente = cl.id_cliente
WHERE  pe.id_pedido IS NULL
ORDER  BY cl.data_cadastro;

-- [Q17] Pedidos com valor acima do ticket médio geral (top 10).
-- Recursos: SUBCONSULTA escalar no WHERE, uso da VIEW, JOIN
SELECT pe.id_pedido, cl.razao_social, pe.data_pedido,
       ROUND(vt.valor_total, 2) AS valor_pedido
FROM   pedido pe
JOIN   cliente         cl ON cl.id_cliente = pe.id_cliente
JOIN   vw_pedido_total vt ON vt.id_pedido  = pe.id_pedido
WHERE  vt.valor_total > (SELECT AVG(valor_total) FROM vw_pedido_total)
ORDER  BY vt.valor_total DESC
LIMIT  10;

-- [Q18] Entregas realizadas com atraso, com cliente e motorista.
-- Recursos: JOIN (4 tabelas), DATEDIFF, relação 1:1
SELECT en.id_pedido,
       cl.razao_social AS cliente,
       mo.nome         AS motorista,
       en.data_prevista,
       en.data_entrega,
       DATEDIFF(en.data_entrega, en.data_prevista) AS dias_de_atraso
FROM   entrega   en
JOIN   pedido    pe ON pe.id_pedido    = en.id_pedido
JOIN   cliente   cl ON cl.id_cliente   = pe.id_cliente
JOIN   motorista mo ON mo.id_motorista = en.id_motorista
WHERE  en.status = 'ENTREGUE'
  AND  en.data_entrega > en.data_prevista
ORDER  BY dias_de_atraso DESC, en.id_pedido
LIMIT  10;

-- [Q19] Inadimplência: parcelas atrasadas e dias de atraso até 25/06/2026.
-- Recursos: JOIN (3 tabelas), DATEDIFF, filtro por status
SELECT cl.razao_social AS cliente,
       pa.id_pedido,
       pa.parcela,
       pa.forma_pagamento,
       pa.valor,
       pa.data_vencimento,
       DATEDIFF('2026-06-25', pa.data_vencimento) AS dias_em_atraso
FROM   pagamento pa
JOIN   pedido    pe ON pe.id_pedido  = pa.id_pedido
JOIN   cliente   cl ON cl.id_cliente = pe.id_cliente
WHERE  pa.status = 'ATRASADO'
ORDER  BY dias_em_atraso DESC;
