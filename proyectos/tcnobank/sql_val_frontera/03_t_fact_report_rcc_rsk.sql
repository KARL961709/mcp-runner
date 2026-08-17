-- 03. FRONTERA DE T_FACT_REPORT_RCC_RSK
--   hasta que mes hay FILAS, no particiones declaradas. Cuenta, no max():
--   una particion vacia declara un mes que no existe (regla E1)
SELECT p_codmes AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT key_value) AS n_personas
  FROM e_perm_aws.t_fact_report_rcc_rsk
 WHERE CAST(p_codmes AS VARCHAR) >= '202512'
 GROUP BY p_codmes
 ORDER BY 1
