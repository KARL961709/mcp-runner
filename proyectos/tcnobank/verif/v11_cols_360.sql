-- ============================================================================
-- V11. COLUMNAS DEL 360 - HAY UN TOTAL DE PASIVO SIN CTS
--   scan: metadato, no datos
--   ancla: el script de nodos suma saldo_fdp_tot_pas_sin_cts de una tabla de datalab
--          que no alcanzamos. Mis 7 componentes son un subconjunto de eso, y por eso
--          mi flag prende 17.3 contra 26.1. Si el 360 tiene la columna equivalente se
--          replica sin datalab
-- ============================================================================
DESCRIBE e_perm_aws.t_aws_360_cliente_mes_d3
