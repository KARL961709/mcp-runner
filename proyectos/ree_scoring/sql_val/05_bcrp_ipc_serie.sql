-- 05. SERIE MACRO GOBERNADA, TRAMO RECIENTE
--   porc_ipc debe reproducir la columna IPC_Lima_var_12m del parquet (que pese al
--   nombre contiene la variacion MENSUAL, ticker PN01271PM). Los meses posteriores
--   a 202604 son los que el parquet no tiene y extienden el factor macro.
SELECT CAST(cod_mes AS VARCHAR)                                                   AS cod_mes,
       porc_ipc
  FROM e_perm_aws.t_mst_bcrp_rsk
 WHERE CAST(cod_mes AS VARCHAR) >= '202301'
 ORDER BY 1
