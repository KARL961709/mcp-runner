-- h01 perfil REAL de altas PP por GRADO (CASE de Carlos sobre el score real) x R x tipo — n, score, PD calibrada y RD real. Base del artifact
WITH j AS (
  SELECT
    CASE WHEN a.sub_producto='PP_CD' THEN a.puntuacion_modelo_cal_ppcd ELSE a.puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN a.sub_producto='PP_CD' THEN a.prob_modelo_cal_ppcd ELSE a.prob_modelo_cal_ppfacil END AS pd_cal,
    a.tipo_ingreso, a.sub_producto, a.target_12m,
    r.r_label_reest, CASE WHEN r.r_nivel_reest >= 1 THEN 1 ELSE 0 END AS pac
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202301' AND '202507'
),
g AS (
  SELECT *,
    CASE WHEN punt >= 993 THEN 'G1' WHEN punt >= 972 THEN 'G2' WHEN punt >= 959 THEN 'G3'
         WHEN punt >= 921 THEN 'G4' WHEN punt >= 884 THEN 'G5' WHEN punt >= 850 THEN 'G6'
         WHEN punt >= 0   THEN 'GR' END AS grupo_riesgo_pp
  FROM j
)
SELECT grupo_riesgo_pp, r_label_reest, tipo_ingreso, pac,
  count(*) AS n,
  round(avg(punt),1) AS punt_prom,
  round(avg(pd_cal),4) AS pdcal_prom,
  round(avg(CAST(target_12m AS double)),4) AS rd12
FROM g
GROUP BY grupo_riesgo_pp, r_label_reest, tipo_ingreso, pac
ORDER BY grupo_riesgo_pp, r_label_reest, tipo_ingreso
