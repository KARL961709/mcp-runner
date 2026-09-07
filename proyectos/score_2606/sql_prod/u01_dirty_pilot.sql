-- ============================================================================
-- u01_dirty PILOTO: flg_dirty_tc / flg_dirty_pp por producto (replica flg_clean desplegado), a m-2 + ventanas.
--   TC: clasif/castigo(u24m)/refin(u6m)/reest(o)/judicial(u24m)/bancarizado(u12m)/GH-convenio/edad.
--   PP: clasif(ALLSF)/castigo(u24m)/refin(u6m)/reest(u6m)/judicial(u24m)/bancarizado(u12m)/edad/entidad00004. GH y SALDO_PP -> clean.
--   bancarizado = SIN sld_bank en u12m -> dirty. Ventana RCC 202506-202607. EC = all-clean (no lleva dirty).
-- ============================================================================
CREATE TABLE disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_dirty_pilot
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH drv AS (
  SELECT CAST(a.codmes AS varchar) AS codmes, a.key_value, CAST(a.cod_tip_doc AS varchar) AS cod_tip_doc, b.sbs_value
  FROM (
    SELECT codmes, key_value, cod_tip_doc, probabilidad,
           ROW_NUMBER() OVER (PARTITION BY codmes, key_value, cod_tip_doc ORDER BY probabilidad DESC) AS rn
    FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
    WHERE probabilidad IS NOT NULL AND cod_tip_doc = '1'
      AND CAST(codmes AS varchar) BETWEEN '202607' AND '202607'
  ) a
  LEFT JOIN (
    SELECT tip_doc, key_value, sbs_value,
           ROW_NUMBER() OVER (PARTITION BY tip_doc, key_value ORDER BY fch_actualizacion DESC) AS rnb
    FROM e_perm_aws.t_mst_ctarcc_rsk
    WHERE tip_doc = '1' AND tip_persona = '1' AND key_value IS NOT NULL AND sbs_value IS NOT NULL
  ) b ON CAST(b.tip_doc AS varchar) = a.cod_tip_doc AND b.key_value = a.key_value AND b.rnb = 1
  WHERE a.rn = 1
),
rcc AS (
  SELECT tip_doc, key_value, CAST(codmes AS varchar) AS rmes, cod_cuenta_rcc, cod_clasificacion_deudor, cod_instit_financiera, tipo_credito
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS varchar) BETWEEN '202506' AND '202607'
),
rccw AS (
  SELECT d.codmes, d.cod_tip_doc, d.key_value,
    MAX(CASE WHEN r.rmes = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (r.cod_clasificacion_deudor IN ('2','3','4')) THEN 1 ELSE 0 END) AS f_clas_o,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3) IN ('302','925')) THEN 1 ELSE 0 END) AS f_cast_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -7, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (((SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='4') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(r.cod_cuenta_rcc,7,2)='19')) AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_ref_w,
    MAX(CASE WHEN r.rmes = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (((SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='3') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(r.cod_cuenta_rcc,7,2)='22')) AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_ree_o,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -7, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (((SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='3') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1405','1406') AND SUBSTR(r.cod_cuenta_rcc,7,2)='22')) AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_ree_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND (SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1)='6' AND r.cod_clasificacion_deudor<>'8') THEN 1 ELSE 0 END) AS f_jud_w,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -13, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND ((((SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3)='923') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,3)='720506') OR (SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')) OR (SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3) IN ('302','925'))) AND r.tipo_credito IN ('11','12','13')) OR ((SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3) IN ('302','925')) AND r.tipo_credito IN ('99'))) THEN 1 ELSE 0 END) AS f_bank_tc,
    MAX(CASE WHEN r.rmes BETWEEN date_format(date_add('month', -13, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND ((SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3)='923') OR (SUBSTR(r.cod_cuenta_rcc,1,2)||'0'||SUBSTR(r.cod_cuenta_rcc,4,3)='720506') OR (SUBSTR(r.cod_cuenta_rcc,1,2)='14' AND SUBSTR(r.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')) OR (SUBSTR(r.cod_cuenta_rcc,1,2)='81' AND SUBSTR(r.cod_cuenta_rcc,4,3) IN ('302','925'))) THEN 1 ELSE 0 END) AS f_bank_pp,
    MAX(CASE WHEN r.rmes = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m') AND r.cod_instit_financiera = '00004' THEN 1 ELSE 0 END) AS f_ent4_o
  FROM drv d
  JOIN rcc r ON CAST(r.tip_doc AS varchar) = d.cod_tip_doc AND r.key_value = d.key_value
            AND r.rmes BETWEEN date_format(date_add('month', -25, date_parse(d.codmes, '%Y%m')), '%Y%m') AND date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m')
  GROUP BY d.codmes, d.cod_tip_doc, d.key_value
),
gh AS (
  SELECT d.codmes, d.key_value,
    MAX(CASE WHEN c.cons_salgarhip > 0 THEN 1 ELSE 0 END) AS f_gh,
    MAX(CASE WHEN c.cons_salprestnorevconv > 0 OR c.cons_salprestrevconv > 0 OR c.cons_salpresconvob > 0 THEN 1 ELSE 0 END) AS f_conv
  FROM drv d
  LEFT JOIN e_perm_aws.t_consolidado_rsk c
    ON c.sbs_value = d.sbs_value AND CAST(c.cons_periodo AS varchar) = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m')
  GROUP BY d.codmes, d.key_value
),
ed AS (
  SELECT d.codmes, d.key_value,
    MAX(CASE WHEN e.fec_nacimiento IS NOT NULL
             AND (date_diff('year', CAST(e.fec_nacimiento AS date), date_parse(d.codmes, '%Y%m')) < 21
               OR date_diff('year', CAST(e.fec_nacimiento AS date), date_parse(d.codmes, '%Y%m')) > 75)
        THEN 1 ELSE 0 END) AS f_edad
  FROM drv d
  LEFT JOIN e_perm_aws.t_mst_reniec_rsk e ON CAST(e.tip_doc AS varchar) = d.cod_tip_doc AND e.key_value = d.key_value
  GROUP BY d.codmes, d.key_value
),
clpp AS (
  SELECT d.codmes, d.key_value,
    MAX(CASE WHEN l.pct_clasif_def_m01 > 0 OR l.pct_clasif_dud_m01 > 0 OR l.pct_clasif_per_m01 > 0 THEN 1 ELSE 0 END) AS f_clas_pp
  FROM drv d
  LEFT JOIN e_perm_aws.tbl_rcc_per_allsf_mdl l ON l.key_value = d.key_value AND CAST(l.codmes AS varchar) = date_format(date_add('month', -2, date_parse(d.codmes, '%Y%m')), '%Y%m')
  GROUP BY d.codmes, d.key_value
)
SELECT
  d.cod_tip_doc, d.key_value,
  CASE WHEN COALESCE(w.f_clas_o,0)=1 OR COALESCE(w.f_cast_w,0)=1 OR COALESCE(w.f_ref_w,0)=1
         OR COALESCE(w.f_ree_o,0)=1 OR COALESCE(w.f_jud_w,0)=1 OR COALESCE(w.f_bank_tc,0)=0
         OR COALESCE(g.f_gh,0)=1 OR COALESCE(g.f_conv,0)=1 OR COALESCE(ed.f_edad,0)=1
       THEN 1 ELSE 0 END AS flg_dirty_tc,
  CASE WHEN COALESCE(cp.f_clas_pp,0)=1 OR COALESCE(w.f_cast_w,0)=1 OR COALESCE(w.f_ref_w,0)=1
         OR COALESCE(w.f_ree_w,0)=1 OR COALESCE(w.f_jud_w,0)=1 OR COALESCE(w.f_bank_pp,0)=0
         OR COALESCE(ed.f_edad,0)=1 OR COALESCE(w.f_ent4_o,0)=1
       THEN 1 ELSE 0 END AS flg_dirty_pp,
  d.codmes
FROM drv d
LEFT JOIN rccw w ON w.codmes=d.codmes AND w.cod_tip_doc=d.cod_tip_doc AND w.key_value=d.key_value
LEFT JOIN gh g   ON g.codmes=d.codmes AND g.key_value=d.key_value
LEFT JOIN ed     ON ed.codmes=d.codmes AND ed.key_value=d.key_value
LEFT JOIN clpp cp ON cp.codmes=d.codmes AND cp.key_value=d.key_value