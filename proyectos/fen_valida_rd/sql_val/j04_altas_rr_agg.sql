-- j04 altas PP VALIDACION agregado grado x tipo x R_reest x R_dir (insumo del toggle "R reestructurado vs directo" del artifact). Mismo universo que j01 (clean IBK, 202301-202507, RD 12m madura, 81 728). Devuelve n, pd media, rd media por celda CONJUNTA (r_reest x r_dir): el artifact deriva de aqui la vista por r_reest y la vista por r_dir desde el MISMO dato. Agregado chico (<=504 filas) -> vuelve por _resultados.txt. Todo el score sale de mca_bd_reniec_xy_r_reest
WITH j AS (
  SELECT
    CASE WHEN a.sub_producto='PP_CD' THEN a.puntuacion_modelo_cal_ppcd ELSE a.puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN a.sub_producto='PP_CD' THEN a.prob_modelo_cal_ppcd ELSE a.prob_modelo_cal_ppfacil END AS pd_cal,
    a.tipo_ingreso, a.target_12m,
    CAST(r.r_nivel AS integer) AS r_dir, CAST(r.r_nivel_reest AS integer) AS r_reest
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202301' AND '202507'
)
SELECT
  CASE WHEN punt >= 993 THEN 'G1' WHEN punt >= 972 THEN 'G2' WHEN punt >= 959 THEN 'G3'
       WHEN punt >= 921 THEN 'G4' WHEN punt >= 884 THEN 'G5' WHEN punt >= 850 THEN 'G6'
       ELSE 'GR' END AS grado,
  tipo_ingreso AS tipo,
  r_reest, r_dir,
  count(*) AS n,
  round(avg(pd_cal), 5) AS pd,
  round(avg(CAST(target_12m AS double)), 5) AS rd
FROM j
GROUP BY 1, 2, 3, 4
