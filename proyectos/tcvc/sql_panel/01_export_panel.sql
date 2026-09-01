-- 01. Panel para ciclo/rho + seleccion macro: RD por entidad x mes x flg_clean (TODAS las entidades, 2019+).
--     Agregado, SIN key_value. Historico largo para LRA/macro. clean = flg_clean=1.
CREATE TABLE disc_model_owner.tcvc_panel_export
WITH (format = 'PARQUET', write_compression = 'SNAPPY', external_location = '<S3_DATOS>/tcvc_panel/') AS
SELECT cod_instit_financiera, codmes, flg_clean,
       COUNT(*) AS n, SUM(target_12m) AS malos,
       AVG(CAST(target_12m AS double)) AS rd
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE target_12m IS NOT NULL
GROUP BY cod_instit_financiera, codmes, flg_clean