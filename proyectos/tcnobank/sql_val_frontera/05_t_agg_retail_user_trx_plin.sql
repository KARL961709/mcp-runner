-- 05. FRONTERA DE T_AGG_RETAIL_USER_TRX_PLIN
--   hasta que mes hay FILAS, no particiones declaradas. Cuenta, no max():
--   una particion vacia declara un mes que no existe (regla E1)
SELECT p_codmes AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT cif_key) AS n_personas
  FROM e_perm_aws.t_agg_retail_user_trx_plin
 WHERE CAST(p_codmes AS VARCHAR) >= '202512'
 GROUP BY p_codmes
 ORDER BY 1
