-- desemb_corr_bajar.sql | EXPORT via SELECT: baja el CSV del resultado a output (NO usa -Bajar, que sincroniza todo S3Datos). Solo las 19 columnas del re-fit + filas cruzadas. Cruce corregido p_codmes=cod_mes-1. Read-only.
SELECT cod_mes, cod_tip_doc, desc_cliente, desc_producto,
       pd_raw, mto_desembolso, meses_madurez,
       target_01m, target_02m, target_03m, target_04m, target_05m, target_06m, target_07m, target_08m, target_09m, target_10m, target_11m, target_12m
FROM disc_model_owner.b46029_desemb_cal_corr_202609
WHERE pd_raw IS NOT NULL
