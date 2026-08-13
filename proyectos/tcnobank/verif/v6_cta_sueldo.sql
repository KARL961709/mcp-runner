-- ============================================================================
-- V6. CUENTA SUELDO - LISTA A TODOS CON FLAG O SOLO A LOS QUE TIENEN
--   scan: e_perm_aws.t_rsk_cta_sueldo por anio
--   ancla: U12 de Reenganche quedo ABIERTA. Si n_flag_0 es cero, la fuente es un
--          listado de quien TIENE cuenta sueldo y la ausencia significa no tiene. Si
--          hay ceros medidos, la ausencia es hueco y un COALESCE a cero mueve el
--          driver con la disponibilidad del dato y no con el cliente
-- ============================================================================
SELECT substr(CAST(codmes AS VARCHAR), 1, 4)                                            AS anio,
       count(*)                                                                         AS n_filas,
       count(DISTINCT CAST(codmes AS VARCHAR))                                          AS n_meses,
       min(CAST(codmes AS VARCHAR))                                                     AS mes_min,
       max(CAST(codmes AS VARCHAR))                                                     AS mes_max,
       count(DISTINCT key_value)                                                        AS n_clientes,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) = 1 THEN 1 ELSE 0 END)         AS n_flag_1,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) = 0 THEN 1 ELSE 0 END)         AS n_flag_0,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) IS NULL THEN 1 ELSE 0 END)     AS n_flag_nulo
FROM e_perm_aws.t_rsk_cta_sueldo
GROUP BY substr(CAST(codmes AS VARCHAR), 1, 4)
ORDER BY anio
