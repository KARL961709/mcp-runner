-- desemb_maestra_c_qa.sql | QA de la maestra (read-only -> _resultados.txt). Corre despues del build.
-- [1] CONTEO: maestra == base == user_desembolso (distinct 4-key). 0 filas perdidas.
SELECT 'conteo' AS chk,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_202609) AS n_maestra,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_cal_202609)     AS n_base,
  (SELECT COUNT(*) FROM (SELECT DISTINCT cod_mes,cod_tip_doc,key_value,desc_producto FROM d_perm_aws.user_desembolso)) AS n_user_desemb;

-- [2] todo pd_raw => pd_pit (0 excepciones); nulos de cada PD donde flg_cruce=1
SELECT 'nulos_bank' AS chk, COUNT(*) AS n_bank,
  SUM(CASE WHEN pd_ttc IS NULL THEN 1 ELSE 0 END) AS ttc_null,
  SUM(CASE WHEN pd_pit IS NULL THEN 1 ELSE 0 END) AS pit_null,
  SUM(CASE WHEN pd_v2_esc_opt IS NULL THEN 1 ELSE 0 END) AS v2_null
FROM disc_model_owner.b46029_desemb_maestra_202609 WHERE flg_cruce=1;

-- [3] rangos + cobertura flg_cruce por personeria
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(*) AS n, ROUND(100.0*AVG(flg_cruce),1) AS pct_cruce,
  ROUND(100*MIN(pd_pit),3) AS min_pit, ROUND(100*MAX(pd_pit),3) AS max_pit,
  ROUND(100*MIN(pd_v2_esc_opt),3) AS min_v2, ROUND(100*MAX(pd_v2_esc_opt),3) AS max_v2
FROM disc_model_owner.b46029_desemb_maestra_202609 GROUP BY 1 ORDER BY 1;

-- [4] BACKTEST: cada PD vs RD12 realizada (maduras, universo de calibracion) por personeria
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(CASE WHEN meses_madurez=12 THEN 1 END) AS n_mad,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_raw END),2)        AS pd_raw,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_ttc END),2)        AS pd_ttc,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_pit END),2)        AS pd_pit,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_v2_esc_opt END),2) AS pd_v2_escopt,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2)    AS rd12
FROM disc_model_owner.b46029_desemb_maestra_202609
WHERE flg_cruce=1 AND flg_universo_calib=1 AND cod_mes>=202401
GROUP BY 1 ORDER BY 1;

-- [5] completitud por mes (meses sin pd_pit entre los bank)
SELECT cod_mes, COUNT(*) AS n, SUM(flg_cruce) AS n_bank,
  SUM(CASE WHEN flg_cruce=1 AND pd_pit IS NULL THEN 1 ELSE 0 END) AS bank_sin_pit
FROM disc_model_owner.b46029_desemb_maestra_202609 GROUP BY cod_mes ORDER BY cod_mes;
