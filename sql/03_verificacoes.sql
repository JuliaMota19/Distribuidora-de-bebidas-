-- =====================================================================
--  SCRIPT AUXILIAR 1 - Verificações pós-carga
--  Confirma a contagem de registros (mínimo exigido: 15 por tabela)
--  e a consistência dos dados. Cada verificação deve retornar OK.
-- =====================================================================
USE distribuidora_bebidas;

-- 1) Quantidade de registros por tabela
SELECT 'cidade' AS tabela, COUNT(*) AS registros FROM cidade
UNION ALL SELECT 'categoria',          COUNT(*) FROM categoria
UNION ALL SELECT 'marca',              COUNT(*) FROM marca
UNION ALL SELECT 'fornecedor',         COUNT(*) FROM fornecedor
UNION ALL SELECT 'produto',            COUNT(*) FROM produto
UNION ALL SELECT 'produto_fornecedor', COUNT(*) FROM produto_fornecedor
UNION ALL SELECT 'estoque',            COUNT(*) FROM estoque
UNION ALL SELECT 'cliente',            COUNT(*) FROM cliente
UNION ALL SELECT 'vendedor',           COUNT(*) FROM vendedor
UNION ALL SELECT 'motorista',          COUNT(*) FROM motorista
UNION ALL SELECT 'pedido',             COUNT(*) FROM pedido
UNION ALL SELECT 'item_pedido',        COUNT(*) FROM item_pedido
UNION ALL SELECT 'pagamento',          COUNT(*) FROM pagamento
UNION ALL SELECT 'entrega',            COUNT(*) FROM entrega;

-- 2) Toda tabela tem pelo menos 15 registros?
SELECT IF(MIN(n) >= 15, 'OK - todas as tabelas com 15+ registros', 'FALHA') AS verificacao
FROM (
    SELECT COUNT(*) AS n FROM cidade UNION ALL SELECT COUNT(*) FROM categoria
    UNION ALL SELECT COUNT(*) FROM marca       UNION ALL SELECT COUNT(*) FROM fornecedor
    UNION ALL SELECT COUNT(*) FROM produto     UNION ALL SELECT COUNT(*) FROM produto_fornecedor
    UNION ALL SELECT COUNT(*) FROM estoque     UNION ALL SELECT COUNT(*) FROM cliente
    UNION ALL SELECT COUNT(*) FROM vendedor    UNION ALL SELECT COUNT(*) FROM motorista
    UNION ALL SELECT COUNT(*) FROM pedido      UNION ALL SELECT COUNT(*) FROM item_pedido
    UNION ALL SELECT COUNT(*) FROM pagamento   UNION ALL SELECT COUNT(*) FROM entrega
) t;

-- 3) A soma das parcelas de cada pedido é igual ao valor total dos itens?
SELECT IF(COUNT(*) = 0, 'OK - parcelas conferem com o total dos pedidos', 'FALHA') AS verificacao
FROM (
    SELECT pa.id_pedido
    FROM   pagamento pa
    JOIN   vw_pedido_total vt ON vt.id_pedido = pa.id_pedido
    GROUP  BY pa.id_pedido, vt.valor_total
    HAVING ABS(SUM(pa.valor) - vt.valor_total) > 0.01
) x;

-- 4) Pedidos faturados/entregues sem nenhum pagamento registrado?
SELECT IF(COUNT(*) = 0, 'OK - todo pedido faturado/entregue possui pagamento', 'FALHA') AS verificacao
FROM   pedido pe
LEFT   JOIN pagamento pa ON pa.id_pedido = pe.id_pedido
WHERE  pe.status IN ('FATURADO', 'ENTREGUE') AND pa.id_pagamento IS NULL;

-- 5) Pedidos entregues sem entrega registrada (ou entrega sem pedido entregue)?
SELECT IF(COUNT(*) = 0, 'OK - status do pedido coerente com a tabela entrega', 'FALHA') AS verificacao
FROM   pedido pe
LEFT   JOIN entrega en ON en.id_pedido = pe.id_pedido
WHERE  (pe.status = 'ENTREGUE' AND (en.id_entrega IS NULL OR en.status <> 'ENTREGUE'))
   OR  (pe.status IN ('ABERTO', 'CANCELADO') AND en.id_entrega IS NOT NULL);

-- 6) Todo pedido possui ao menos um item?
SELECT IF(COUNT(*) = 0, 'OK - nenhum pedido sem itens', 'FALHA') AS verificacao
FROM   pedido pe
LEFT   JOIN item_pedido ip ON ip.id_pedido = pe.id_pedido
WHERE  ip.id_pedido IS NULL;
