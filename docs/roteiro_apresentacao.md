# Roteiro da apresentação oral (15 min + 5 min de arguição)

Ambos os integrantes devem falar. Sugestão de divisão (ajustem conforme a afinidade de cada um):

| Tempo | Etapa | Quem | O que mostrar |
|---|---|---|---|
| 1–2 min | **Introdução** | Integrante A | Domínio (distribuidora de bebidas), por que foi escolhido e o ciclo do negócio: comprar → estocar → vender → receber → entregar |
| 3–4 min | **Modelagem** | Integrante A | DER (`img/der_distribuidora_bebidas.png`): as 2 relações N:N, as 2 relações 1:1, a tabela `cidade` como exemplo de 3FN |
| 2 min | **Demonstração das tabelas** | Integrante B | No Workbench ou terminal: `SHOW TABLES;`, `DESCRIBE produto;`, `SELECT * FROM pedido LIMIT 5;` e `03_verificacoes.sql` |
| 6–7 min | **Consultas ao vivo** | A e B, alternando | Ao menos 10 consultas. Sugestão: **A** Q01, Q03, Q07, Q09, Q10; **B** Q11, Q12, Q13, Q15, Q17. Para cada uma: pergunta de negócio → SQL → leitura do resultado |
| 1 min | **Encerramento** | Integrante B | Decisões de projeto (venda por caixa, total derivado, RESTRICT/CASCADE) e evoluções (triggers, endereços, notas fiscais) |

> Dica: rode `04_testes_restricoes.sql` (T2, T5 e T9) caso sobre tempo. Mostrar um erro de `CHECK` e um `CASCADE` funcionando impressiona.

## Perguntas prováveis na arguição

**1. Por que o esquema está em 3FN? Dê um exemplo.**
Porque nenhum atributo não-chave depende de outro não-chave. Exemplo: se `cliente` guardasse `cidade` e `uf`, teríamos `id_cliente → cidade → uf` (dependência transitiva). Por isso criamos `cidade(id_cidade, nome, uf)`.

**2. Por que `pedido` não tem um campo `valor_total`?**
É um dado derivado: a soma dos itens. Guardá-lo geraria redundância e risco de ficar desatualizado. Ele é calculado pela view `vw_pedido_total`.

**3. Por que `item_pedido.preco_unitario` existe se `produto` já tem `preco_venda`?**
`preco_venda` é o preço *atual*; `preco_unitario` é o preço *praticado na data da venda*. Sem ele, um reajuste mudaria o valor de pedidos antigos.

**4. Como funciona a relação N:N? Por que a PK de `item_pedido` é composta?**
Um pedido tem vários produtos e um produto está em vários pedidos. A tabela associativa guarda uma linha por par (pedido, produto); a PK composta impede o mesmo produto duas vezes no mesmo pedido.

**5. Como o banco garante a relação 1:1 entre `pedido` e `entrega`?**
Com `UNIQUE` em `entrega.id_pedido`. Em `estoque`, o próprio `id_produto` é PK e FK ao mesmo tempo. O teste T8 mostra o erro ao tentar uma segunda entrega.

**6. Por que `ON DELETE RESTRICT` em `pedido → cliente` e `CASCADE` em `item_pedido → pedido`?**
O cliente é um dado histórico e não pode sumir se tem pedidos. Já os itens não fazem sentido sem o pedido, então saem junto com ele.

**7. Qual a diferença entre `WHERE` e `HAVING`? Mostre em uma consulta.**
`WHERE` filtra linhas *antes* de agrupar; `HAVING` filtra os *grupos* depois da agregação. Na Q09, `WHERE` exclui pedidos cancelados e `HAVING` mantém só clientes com faturamento acima de R$ 4.000.

**8. Qual a diferença entre `INNER JOIN` e `LEFT JOIN`?**
`INNER JOIN` só traz linhas com correspondência nas duas tabelas. `LEFT JOIN` traz todas da esquerda, com `NULL` quando não há par. Na Q15 e na Q16, isso identifica produtos nunca vendidos e clientes que nunca compraram (`IS NULL`).

**9. Explique a subconsulta da Q17.**
A subconsulta `(SELECT AVG(valor_total) FROM vw_pedido_total)` calcula o ticket médio uma vez, e a consulta externa lista os pedidos acima dele.

**10. Por que `COUNT(DISTINCT pe.id_pedido)` na Q09 e Q11?**
Porque o JOIN com `item_pedido` multiplica as linhas do pedido (uma por item). Sem `DISTINCT`, o mesmo pedido seria contado várias vezes.

**11. O que acontece se eu excluir um fornecedor?**
Os vínculos dele em `produto_fornecedor` são removidos (`CASCADE`), mas os produtos continuam existindo. Teste T9 do script `04`.

**12. O que é a view `vw_pedido_total` e por que usá-la?**
É uma consulta salva que se comporta como tabela virtual. Ela centraliza o cálculo do total do pedido para que todas as consultas usem a mesma regra.
