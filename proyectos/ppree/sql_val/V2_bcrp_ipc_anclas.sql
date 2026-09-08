-- ============================================================================
-- V2. IPC BCRP: chequeo de escala/nulos + meses ancla (agregado de 1 fila)
-- ============================================================================
SELECT
  COUNT(*)                                                          AS n_meses,
  MIN(CAST(cod_mes AS INTEGER))                                     AS codmes_min,
  MAX(CAST(cod_mes AS INTEGER))                                     AS codmes_max,
  SUM(CASE WHEN porc_ipc IS NULL THEN 1 ELSE 0 END)                 AS n_null,
  MIN(porc_ipc)                                                     AS ipc_min,
  MAX(porc_ipc)                                                     AS ipc_max,
  MAX(CASE WHEN CAST(cod_mes AS INTEGER) = 202112 THEN porc_ipc END) AS ipc_202112,
  MAX(CASE WHEN CAST(cod_mes AS INTEGER) = 202206 THEN porc_ipc END) AS ipc_202206,
  MAX(CASE WHEN CAST(cod_mes AS INTEGER) = 202604 THEN porc_ipc END) AS ipc_202604
FROM e_perm_aws.t_mst_bcrp_rsk
