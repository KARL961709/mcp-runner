-- 06. FRONTERA DE T_RSK_CTA_SUELDO
--   hasta que mes hay FILAS, no particiones declaradas. Cuenta, no max():
--   una particion vacia declara un mes que no existe (regla E1)
SELECT CAST(codmes AS VARCHAR) AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT key_value) AS n_personas
  FROM e_perm_aws.t_rsk_cta_sueldo
 WHERE CAST(codmes AS VARCHAR) >= '202512'
 GROUP BY CAST(codmes AS VARCHAR)
 ORDER BY 1
