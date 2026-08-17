-- 04. FRONTERA DE T_AWS_360_CLIENTE_MES_D3
--   hasta que mes hay FILAS, no particiones declaradas. Cuenta, no max():
--   una particion vacia declara un mes que no existe (regla E1)
SELECT CAST(codmes AS VARCHAR) AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT key_value) AS n_personas
  FROM e_perm_aws.t_aws_360_cliente_mes_d3
 WHERE CAST(codmes AS VARCHAR) >= '202512'
 GROUP BY CAST(codmes AS VARCHAR)
 ORDER BY 1
