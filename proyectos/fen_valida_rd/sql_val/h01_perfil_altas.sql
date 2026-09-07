-- h01 perfil REAL de altas PP por GRADO x R x tipo (grado = CASE sobre puntuacion_cal_ppfacil) — n, score, PD y RD real. Base del artifact (agregado, sin PII)
WITH j AS (
  SELECT
    CASE WHEN a.puntuacion_cal_ppfacil >= 993 THEN 'G1'
         WHEN a.puntuacion_cal_ppfacil >= 972 THEN 'G2'
         WHEN a.puntuacion_cal_ppfacil >= 959 THEN 'G3'
         WHEN a.puntuacion_cal_ppfacil >= 921 THEN 'G4'
         WHEN a.puntuacion_cal_ppfacil >= 884 THEN 'G5'
         WHEN a.puntuacion_cal_ppfacil >= 850 THEN 'G6'
         WHEN a.puntuacion_cal_ppfacil >= 0   THEN 'GR' END AS grupo_riesgo_pp,
    a.tipo_ingreso, r.r_label_reest,
    CASE WHEN r.r_nivel_reest >= 1 THEN 1 ELSE 0 END AS pac,
    a.pd_raw, a.puntuacion_cal_ppfacil, a.target_12m
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202301' AND '202507'
)
SELECT grupo_riesgo_pp, r_label_reest, tipo_ingreso, pac,
  count(*) AS n,
  round(avg(puntuacion_cal_ppfacil),1) AS punt_prom,
  round(avg(pd_raw),4) AS pd_prom,
  round(avg(CAST(target_12m AS double)),4) AS rd12
FROM j
GROUP BY grupo_riesgo_pp, r_label_reest, tipo_ingreso, pac
ORDER BY grupo_riesgo_pp, r_label_reest, tipo_ingreso
