-- ============================================================================
-- V1. IPC BCRP: serie mensual porc_ipc (verificacion vs parquet calibracion)
--     Llave cod_mes. Rango 201801-202604 para calzar con el parquet macro.
--     Anclas esperadas (IPC_Lima anual %): 202112~6.43  202206~8.81  202604~4.01
-- ============================================================================
SELECT
  CAST(cod_mes AS VARCHAR) AS cod_mes,
  porc_ipc
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE CAST(cod_mes AS INTEGER) BETWEEN 201801 AND 202604
ORDER BY 1
