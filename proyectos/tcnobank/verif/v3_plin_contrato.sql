-- ============================================================================
-- V3. PLIN - RANGO, GRANO Y SI NUMERO_TRX SE PUEDE SUMAR
--   scan: e_perm_aws.t_agg_retail_user_trx_plin por anio
--   ancla: numero_trx viene como STRING, asi que el sum() de VARIABLES PLIN V2 suma
--          texto o falla. Tambien se mide si codmes y p_codmes concuerdan
-- ============================================================================
SELECT substr(CAST(p_codmes AS VARCHAR), 1, 4)                                          AS anio,
       count(*)                                                                         AS n_filas,
       count(DISTINCT CAST(p_codmes AS VARCHAR))                                        AS n_meses,
       min(CAST(p_codmes AS VARCHAR))                                                   AS mes_min,
       max(CAST(p_codmes AS VARCHAR))                                                   AS mes_max,
       count(DISTINCT cif_key)                                                          AS n_clientes,
       count(DISTINCT tipo_transf)                                                      AS n_tipo_transf,
       count(DISTINCT banco)                                                            AS n_bancos,
       sum(CASE WHEN TRY_CAST(numero_trx AS INTEGER) IS NULL THEN 1 ELSE 0 END)         AS n_trx_no_casteable,
       sum(CASE WHEN CAST(codmes AS VARCHAR) <> CAST(p_codmes AS VARCHAR)
                THEN 1 ELSE 0 END)                                                      AS n_codmes_distinto
FROM e_perm_aws.t_agg_retail_user_trx_plin
GROUP BY substr(CAST(p_codmes AS VARCHAR), 1, 4)
ORDER BY anio
