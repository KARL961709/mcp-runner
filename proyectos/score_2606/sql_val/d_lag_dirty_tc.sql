-- d_lag_dirty_tc. DIAGNOSTICO read-only: que LAG (-2/-3/-4) y set de brazos reproduce el flg_clean desplegado de TC.
--   Reconstruye dirty desde e_perm_aws.t_fact_report_rcc_rsk (clasif>CPP / castigo / refin / reest / judicial / mora>0)
--   para admitidos TC (altas_adm_tcbank_cal, flg_ibk=1, 202606-202607) y compara vs flg_clean=0.
--   El lag con MAX agree (MIN miss+extra) es el correcto. miss residual = brazos faltantes (bancarizado / fraude).
--   agree_clasif2 = baseline con solo clasif (lo que hace hoy el universo).
WITH alt AS (
  SELECT CAST(tip_doc AS varchar) AS tip_doc, key_value, CAST(codmes AS varchar) AS codmes,
         CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END AS dep_dirty,
         date_format(date_add('month', -2, date_parse(CAST(codmes AS varchar), '%Y%m')), '%Y%m') AS m2,
         date_format(date_add('month', -3, date_parse(CAST(codmes AS varchar), '%Y%m')), '%Y%m') AS m3,
         date_format(date_add('month', -4, date_parse(CAST(codmes AS varchar), '%Y%m')), '%Y%m') AS m4
  FROM disc_model_owner.altas_adm_tcbank_cal
  WHERE flg_ibk = 1 AND CAST(codmes AS varchar) BETWEEN '202606' AND '202607'
),
j AS (
  SELECT a.tip_doc, a.key_value, a.codmes, a.dep_dirty, a.m2, a.m3, a.m4,
         CAST(b.codmes AS varchar) AS rccmes,
         MAX(CASE WHEN b.cod_clasificacion_deudor IN ('2','3','4') THEN 1 ELSE 0 END) AS hit_clasif,
         MAX(CASE
               WHEN b.cod_clasificacion_deudor IN ('2','3','4') THEN 1
               WHEN SUBSTR(b.cod_cuenta_rcc,1,2) = '81' AND SUBSTR(b.cod_cuenta_rcc,4,3) IN ('302','925') THEN 1
               WHEN ((SUBSTR(b.cod_cuenta_rcc,1,2) = '14' AND SUBSTR(b.cod_cuenta_rcc,4,1) IN ('3','4','6'))
                     OR (SUBSTR(b.cod_cuenta_rcc,1,2) || '0' || SUBSTR(b.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(b.cod_cuenta_rcc,7,2) IN ('19','22')))
                    AND b.cod_clasificacion_deudor <> '8' THEN 1
               WHEN SUBSTR(b.cod_cuenta_rcc,1,2) = '14' AND SUBSTR(b.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                    AND b.cod_clasificacion_deudor <> '8' AND COALESCE(TRY_CAST(b.condicion AS double), 0) > 0 THEN 1
               ELSE 0 END) AS hit_full
  FROM alt a
  JOIN e_perm_aws.t_fact_report_rcc_rsk b
    ON CAST(b.tip_doc AS varchar) = a.tip_doc AND b.key_value = a.key_value
   AND CAST(b.codmes AS varchar) BETWEEN '202602' AND '202605'
   AND CAST(b.codmes AS varchar) IN (a.m2, a.m3, a.m4)
  GROUP BY a.tip_doc, a.key_value, a.codmes, a.dep_dirty, a.m2, a.m3, a.m4, CAST(b.codmes AS varchar)
),
percli AS (
  SELECT a.tip_doc, a.key_value, a.codmes, a.dep_dirty,
    COALESCE(MAX(CASE WHEN j.rccmes = a.m2 THEN j.hit_full END), 0) AS rf2,
    COALESCE(MAX(CASE WHEN j.rccmes = a.m3 THEN j.hit_full END), 0) AS rf3,
    COALESCE(MAX(CASE WHEN j.rccmes = a.m4 THEN j.hit_full END), 0) AS rf4,
    COALESCE(MAX(CASE WHEN j.rccmes = a.m2 THEN j.hit_clasif END), 0) AS rc2
  FROM alt a
  LEFT JOIN j ON j.tip_doc = a.tip_doc AND j.key_value = a.key_value AND j.codmes = a.codmes
  GROUP BY a.tip_doc, a.key_value, a.codmes, a.dep_dirty
)
SELECT
  COUNT(*) AS n, SUM(dep_dirty) AS n_dep_dirty,
  SUM(rf2) AS rec_full2, SUM(CASE WHEN dep_dirty = rf2 THEN 1 ELSE 0 END) AS agree2,
  SUM(CASE WHEN dep_dirty = 1 AND rf2 = 0 THEN 1 ELSE 0 END) AS miss2,
  SUM(CASE WHEN dep_dirty = 0 AND rf2 = 1 THEN 1 ELSE 0 END) AS extra2,
  SUM(rf3) AS rec_full3, SUM(CASE WHEN dep_dirty = rf3 THEN 1 ELSE 0 END) AS agree3,
  SUM(CASE WHEN dep_dirty = 1 AND rf3 = 0 THEN 1 ELSE 0 END) AS miss3,
  SUM(CASE WHEN dep_dirty = 0 AND rf3 = 1 THEN 1 ELSE 0 END) AS extra3,
  SUM(rf4) AS rec_full4, SUM(CASE WHEN dep_dirty = rf4 THEN 1 ELSE 0 END) AS agree4,
  SUM(CASE WHEN dep_dirty = 1 AND rf4 = 0 THEN 1 ELSE 0 END) AS miss4,
  SUM(CASE WHEN dep_dirty = 0 AND rf4 = 1 THEN 1 ELSE 0 END) AS extra4,
  SUM(rc2) AS rec_clasif2, SUM(CASE WHEN dep_dirty = rc2 THEN 1 ELSE 0 END) AS agree_clasif2
FROM percli
