-- ============================================================================
-- 97. PARQUET MACRO IPC - la serie gobernada cruda, sin transformar
--   porc_ipc es la variacion MENSUAL del IPC, no la interanual (v29: identica a
--   IPC_Lima_var_12m del parquet del v5 a 4.9e-11 en 16 meses comunes).
--   Se exporta CRUDA a proposito: la interanual se compone en Fase 2 con
--   exp(sum(ln(1+x/100))) sobre 12 meses, que reproduce la y/y real a 0.0 exacto
--   en 78 meses. Transformar aca fijaria una sola especificacion y el benchmark
--   macro necesita probar varias.
--   Son ~100 filas: va por parquet y no pegado a mano, para no transcribir.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_macro_ipc
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/macro_ipc/') AS
SELECT
  CAST(cod_mes AS VARCHAR)  AS codmes,
  CAST(porc_ipc AS DOUBLE)  AS porc_ipc_mm
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE porc_ipc IS NOT NULL
