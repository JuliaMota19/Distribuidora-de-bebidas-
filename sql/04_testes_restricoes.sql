-- =====================================================================
--  SCRIPT AUXILIAR 2 - Testes das restrições de integridade
--  Cada comando de [T1] a [T8] DEVE FALHAR com o erro indicado.
--  Para rodar tudo de uma vez no terminal, use a opção --force:
--      mysql -u root -p --force < 04_testes_restricoes.sql
--  No Workbench, selecione e execute um teste por vez.
--  [T9] mostra o comportamento ON DELETE CASCADE (e desfaz com ROLLBACK).
-- =====================================================================
USE distribuidora_bebidas;

-- [T1] FOREIGN KEY: pedido para cliente inexistente.
-- Esperado: erro de chave estrangeira (cliente 9999 não existe).
INSERT INTO pedido (id_cliente, id_vendedor, data_pedido)
VALUES (9999, 1, '2026-07-01');

-- [T2] CHECK: preço de venda menor que o preço de custo.
-- Esperado: violação de ck_produto_precos.
INSERT INTO produto (sku, nome, id_categoria, id_marca, volume_ml, preco_custo, preco_venda)
VALUES ('TST-999', 'Produto Teste', 1, 1, 350, 50.00, 40.00);

-- [T3] CHECK: status de pedido fora do domínio.
-- Esperado: violação de ck_pedido_status.
UPDATE pedido SET status = 'EM_ANALISE' WHERE id_pedido = 1;

-- [T4] UNIQUE: CNPJ duplicado em cliente.
-- Esperado: erro de entrada duplicada (cnpj).
INSERT INTO cliente (razao_social, cnpj, email, telefone, tipo_cliente, id_cidade)
SELECT 'Bar Duplicado Ltda', cnpj, 'duplicado@exemplo.com.br', '(31) 99999-0000', 'BAR', 1
FROM   cliente WHERE id_cliente = 1;

-- [T5] ON DELETE RESTRICT: excluir cliente que já possui pedidos.
-- Esperado: erro de chave estrangeira (cliente referenciado por pedido).
DELETE FROM cliente
WHERE id_cliente = (SELECT id_cliente FROM pedido WHERE id_pedido = 1);

-- [T6] CHECK composto: parcela marcada como PAGO sem data de pagamento.
-- Esperado: violação de ck_pagamento_data.
UPDATE pagamento SET status = 'PAGO', data_pagamento = NULL WHERE id_pagamento = 1;

-- [T7] CHECK: desconto acima do limite de 30%.
-- Esperado: violação de ck_item_desconto.
UPDATE item_pedido SET desconto_pct = 45 WHERE id_pedido = 1;

-- [T8] UNIQUE (relação 1:1): segunda entrega para o mesmo pedido.
-- Esperado: erro de entrada duplicada (id_pedido em entrega).
INSERT INTO entrega (id_pedido, id_motorista, data_prevista)
SELECT id_pedido, 1, '2026-07-05' FROM entrega WHERE id_pedido = 1;

-- [T9] ON DELETE CASCADE: excluir um fornecedor remove seus vínculos
-- em produto_fornecedor (e nada mais). Executado dentro de transação.
START TRANSACTION;
SELECT COUNT(*) AS vinculos_antes  FROM produto_fornecedor WHERE id_fornecedor = 1;
DELETE FROM fornecedor WHERE id_fornecedor = 1;
SELECT COUNT(*) AS vinculos_depois FROM produto_fornecedor WHERE id_fornecedor = 1;
ROLLBACK;
SELECT COUNT(*) AS fornecedor_restaurado FROM fornecedor WHERE id_fornecedor = 1;
