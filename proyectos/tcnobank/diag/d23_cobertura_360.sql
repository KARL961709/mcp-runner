-- ============================================================================
-- D23. HASTA DONDE LLEGA LA FUENTE DE PASIVOS Y SI TIENE UNA FILA POR LLAVE
--   scan: e_perm_aws.t_aws_360_cliente_mes_d3 por anio, contando filas
--   ancla: la regla pide 6 meses seguidos, asi que el primer mes usable es fuente+5. Si
--          hay historia previa a 202211 el flag deja de ser reciente. min y max de
--          particion no son evidencia de rango: se cuentan filas.
--          El MAX del create original implica mas de una fila por llave-mes: se mide
-- ============================================================================
SELECT substr(CAST(a.codmes AS VARCHAR), 1, 4)                                          AS anio,
       count(*)                                                                         AS n_filas,
       count(DISTINCT CAST(a.codmes AS VARCHAR))                                        AS n_meses,
       min(CAST(a.codmes AS VARCHAR))                                                   AS mes_min,
       max(CAST(a.codmes AS VARCHAR))                                                   AS mes_max,
       count(DISTINCT a.key_value)                                                      AS n_clientes,
       round(1.0 * count(*) / nullif(count(DISTINCT
             CAST(a.codmes AS VARCHAR) || a.key_value ||
             CAST(a.cod_tipo_documento AS VARCHAR)), 0), 4)                             AS filas_por_llave_mes,
       round(100.0 * avg(CASE WHEN (  coalesce(TRY_CAST(a.saldo_fdp_tot_inversion  AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_millonaria AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_planilla   AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_plazo_fijo AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_txs        AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_alcancia   AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_ahor_cred  AS DOUBLE), 0)) >= 900 THEN 1.0 ELSE 0.0 END), 3)          AS pct_saldo_mayor_900,
       round(100.0 * avg(CASE WHEN (  coalesce(TRY_CAST(a.saldo_fdp_tot_inversion  AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_millonaria AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_planilla   AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_plazo_fijo AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_txs        AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_alcancia   AS DOUBLE), 0)
          + coalesce(TRY_CAST(a.saldo_fdp_tot_ahor_cred  AS DOUBLE), 0))  > 0   THEN 1.0 ELSE 0.0 END), 3)          AS pct_saldo_positivo
FROM e_perm_aws.t_aws_360_cliente_mes_d3 a
GROUP BY substr(CAST(a.codmes AS VARCHAR), 1, 4)
ORDER BY anio
