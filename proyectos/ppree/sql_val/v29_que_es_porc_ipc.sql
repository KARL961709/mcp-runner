-- ============================================================================
-- v29. QUE ES porc_ipc: mensual o interanual?
--   02_score_stock_pp deriva el ft de porc_ipc con MA6 lag5 y declara que
--   reproduce el desplegado a 2.3e-07. Pero IPC_Lima_var_12m, el regresor del
--   v5, es la variacion MENSUAL (medido: identica a la m/m a 8 decimales en 75
--   meses, corr 1.000000). Las dos cosas solo cierran si porc_ipc tambien es
--   mensual. Decide el termino macro de la Opcion 2, que va sobre la y/y.
--   Vuelve el valor crudo por mes: se compara contra las dos series locales.
-- ============================================================================
SELECT
  CAST(cod_mes AS VARCHAR)                  AS cod_mes,
  COUNT(*)                                  AS n_filas,
  ROUND(AVG(porc_ipc), 10)                  AS porc_ipc,
  ROUND(MIN(porc_ipc), 10)                  AS porc_ipc_min,
  ROUND(MAX(porc_ipc), 10)                  AS porc_ipc_max
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE CAST(cod_mes AS VARCHAR) >= '202501'
  AND porc_ipc IS NOT NULL
GROUP BY CAST(cod_mes AS VARCHAR)
ORDER BY 1
