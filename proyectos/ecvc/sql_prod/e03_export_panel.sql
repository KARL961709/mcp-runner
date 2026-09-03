-- e03. Export parquet del panel entidad x codmes x sub_producto (agregado, TODAS las entidades, para ciclo/rho/macro). RD12 = malos12 / n_mad12. -Bajar.
CREATE TABLE disc_model_owner.ecvc_panel_export
WITH (format = 'PARQUET', write_compression = 'SNAPPY', external_location = '<S3_DATOS>/ecvc_panel/') AS
SELECT cod_instit_financiera,
       CAST(codmes AS varchar) AS codmes,
       sub_producto,
       COUNT(*) AS n,
       SUM(flg_pd_raw) AS n_pdraw,
       SUM(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_mad12,
       SUM(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END) AS malos12,
       ROUND(AVG(pd_raw), 6) AS pd_raw_avg
FROM disc_model_owner.ds_ec_cdd_cal
GROUP BY cod_instit_financiera, CAST(codmes AS varchar), sub_producto
