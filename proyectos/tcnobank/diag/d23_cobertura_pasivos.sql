-- ============================================================================
-- D23. HASTA DONDE LLEGA LA FUENTE DE PASIVOS
--   scan: e_perm_aws.t_aws_360_cliente_mes_d3 por codmes, contando filas
--   ancla: T_BASE_PASIVOS_CS corta en 202305 porque la regla pide 6 meses seguidos y la
--          fuente se leyo desde 202211. Si la fuente tiene historia previa, la misma
--          logica se re-corre hacia atras y el flag deja de ser reciente. min y max de
--          particion no sirven como evidencia: se cuentan filas
-- ============================================================================
SELECT substr(CAST(codmes AS VARCHAR), 1, 4)                                            AS anio,
       count(*)                                                                         AS n_filas,
       count(DISTINCT CAST(codmes AS VARCHAR))                                          AS n_meses,
       min(CAST(codmes AS VARCHAR))                                                     AS mes_min,
       max(CAST(codmes AS VARCHAR))                                                     AS mes_max,
       count(DISTINCT key_value)                                                        AS n_clientes
FROM e_perm_aws.t_aws_360_cliente_mes_d3
GROUP BY substr(CAST(codmes AS VARCHAR), 1, 4)
ORDER BY anio
