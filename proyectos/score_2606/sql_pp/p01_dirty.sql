-- p01 dirty RANGO 202401-202606 (opt). flg_dirty_pp = clasif RCC deudor IN (2,3,4) exactamente a m-2 (RCC 202311-202604). Idem 2609 (f_clas_o). Driver opt.
CREATE TABLE disc_model_owner.scr_admvc_pp_cal_202401_202606_dirty
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH drv AS (
  SELECT codmes, key_value, cod_tip_doc FROM (
    SELECT CAST(cod_mes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc,
           ROW_NUMBER() OVER (PARTITION BY cod_mes, key_value, cod_tip_doc ORDER BY prob_model DESC) AS rn
    FROM disc_riesgos.scr_vcbankv3_repro_opt_
    WHERE prob_model IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
      AND CAST(cod_mes AS varchar) BETWEEN '202401' AND '202606'
      AND CAST(p_codmes AS varchar) = CAST(cod_mes AS varchar)
  ) WHERE rn = 1
),
rcc AS (
  SELECT CAST(tip_doc AS varchar) AS tip_doc, key_value, CAST(codmes AS varchar) AS rmes, cod_clasificacion_deudor
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS varchar) BETWEEN '202311' AND '202604'
)
SELECT d.cod_tip_doc, d.key_value,
  MAX(CASE WHEN r.cod_clasificacion_deudor IN ('2','3','4') THEN 1 ELSE 0 END) AS flg_dirty_pp,
  d.codmes
FROM drv d
LEFT JOIN rcc r ON r.tip_doc = d.cod_tip_doc AND r.key_value = d.key_value
  AND r.rmes = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m')
GROUP BY d.cod_tip_doc, d.key_value, d.codmes
