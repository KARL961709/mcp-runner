-- c01 dirty CASCADA PILOTO 202401 (opt). flg_dirty_pp_casc = clasif(m-2) OR castigo(u24m) OR refin(u7m) OR reest(u7m) OR judicial(u25m). SIN bancarizado ni entidad 0004.
--   Emite tambien flg_dirty_pp (clasif-only, = 2609) para comparar. Codigos de cuenta VERBATIM de u01_dirty_2609. RCC m-25..m-2 = 202112..202311. Driver opt.
CREATE TABLE disc_model_owner.scr_admvc_pp_cal_202401_202606_dirty_casc
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH drv AS (
  SELECT codmes, key_value, cod_tip_doc FROM (
    SELECT CAST(cod_mes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc,
           ROW_NUMBER() OVER (PARTITION BY cod_mes, key_value, cod_tip_doc ORDER BY prob_model DESC) AS rn
    FROM disc_riesgos.scr_vcbankv3_repro_opt_
    WHERE prob_model IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
      AND CAST(p_codmes AS varchar) = '202401'
      AND CAST(cod_mes AS varchar) BETWEEN '202401' AND '202401'
  ) WHERE rn = 1
),
rcc AS (
  SELECT CAST(tip_doc AS varchar) AS tip_doc, key_value, CAST(codmes AS varchar) AS rmes, cod_cuenta_rcc, cod_clasificacion_deudor
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS varchar) BETWEEN '202112' AND '202311'
),
w AS (
  SELECT d.codmes, d.cod_tip_doc, d.key_value,
    MAX(CASE WHEN r.rmes = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (r.cod_clasificacion_deudor IN ('2','3','4')) THEN 1 ELSE 0 END) AS f_clas_o,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3) IN ('302','925')) THEN 1 ELSE 0 END) AS f_cast_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -7, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (((SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='4') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(r.cod_cuenta_rcc,7,2)='19')) AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_ref_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -7, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (((SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='3') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(r.cod_cuenta_rcc,7,2)='22')) AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_ree_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='6' AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_jud_w
  FROM drv d
  JOIN rcc r ON r.tip_doc = d.cod_tip_doc AND r.key_value = d.key_value
    AND r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m')
  GROUP BY d.codmes, d.cod_tip_doc, d.key_value
)
SELECT d.cod_tip_doc, d.key_value,
  CASE WHEN COALESCE(w.f_clas_o,0) = 1 THEN 1 ELSE 0 END AS flg_dirty_pp,
  CASE WHEN COALESCE(w.f_clas_o,0) = 1 OR COALESCE(w.f_cast_w,0) = 1 OR COALESCE(w.f_ref_w,0) = 1 OR COALESCE(w.f_ree_w,0) = 1 OR COALESCE(w.f_jud_w,0) = 1 THEN 1 ELSE 0 END AS flg_dirty_pp_casc,
  COALESCE(w.f_clas_o,0) AS a_clas, COALESCE(w.f_cast_w,0) AS a_cast, COALESCE(w.f_ref_w,0) AS a_ref, COALESCE(w.f_ree_w,0) AS a_ree, COALESCE(w.f_jud_w,0) AS a_jud,
  d.codmes
FROM drv d
LEFT JOIN w ON w.codmes = d.codmes AND w.cod_tip_doc = d.cod_tip_doc AND w.key_value = d.key_value
