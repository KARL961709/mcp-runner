-- desemb_corr_slim_build.sql | EXPORT MINIMO para el re-fit: solo las 19 columnas que lee cal_plotly + solo filas cruzadas (pd_raw not null). Baja rapido con -Bajar. Cruce ya corregido (p_codmes = cod_mes-1) heredado de b46029_desemb_cal_corr_202609.
CREATE TABLE disc_model_owner.b46029_desemb_corr_slim_202609
WITH (format='PARQUET', parquet_compression='SNAPPY') AS
SELECT cod_mes, cod_tip_doc, desc_cliente, desc_producto,
       pd_raw, mto_desembolso, meses_madurez,
       target_01m, target_02m, target_03m, target_04m, target_05m, target_06m, target_07m, target_08m, target_09m, target_10m, target_11m, target_12m
FROM disc_model_owner.b46029_desemb_cal_corr_202609
WHERE pd_raw IS NOT NULL
