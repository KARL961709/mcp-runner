-- j01 altas PP 1 a 1 (cliente por cliente) para el simulador FEN: pd_cal, R (0-5), tipo, rd12, grado y ubigeo INEI. Mismos joins/filtros que h01, sin GROUP BY
WITH j AS (
  SELECT
    CASE WHEN a.sub_producto='PP_CD' THEN a.puntuacion_modelo_cal_ppcd ELSE a.puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN a.sub_producto='PP_CD' THEN a.prob_modelo_cal_ppcd ELSE a.prob_modelo_cal_ppfacil END AS pd_cal,
    a.tipo_ingreso, a.target_12m,
    r.r_nivel_reest, r.ubigeo_formato_inei
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202301' AND '202507'
)
SELECT
  round(pd_cal, 5) AS pd,
  r_nivel_reest AS r,
  tipo_ingreso AS tipo,
  CAST(target_12m AS integer) AS rd12,
  CASE WHEN punt >= 993 THEN 'G1' WHEN punt >= 972 THEN 'G2' WHEN punt >= 959 THEN 'G3'
       WHEN punt >= 921 THEN 'G4' WHEN punt >= 884 THEN 'G5' WHEN punt >= 850 THEN 'G6'
       ELSE 'GR' END AS grado,
  ubigeo_formato_inei AS ubigeo
FROM j
