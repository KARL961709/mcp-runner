-- j03 altas PP RECIENTES 1 a 1 (libro vigente a estresar, codmes 202605-202607) — PD calibrada PP + score FEN COMPLETO de reniec (directo + geo + REESTRUCTURADO + fisico + ubigeos + cascada). rd12 INMADURO (no valida, se estresa). Poblacion clean IBK. Todo el score sale de mca_bd_reniec_xy_r_reest
WITH j AS (
  SELECT
    CASE WHEN a.sub_producto='PP_CD' THEN a.puntuacion_modelo_cal_ppcd ELSE a.puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN a.sub_producto='PP_CD' THEN a.prob_modelo_cal_ppcd ELSE a.prob_modelo_cal_ppfacil END AS pd_cal,
    a.codmes, a.sub_producto, a.tipo_ingreso, a.target_12m,
    r.r_label, r.r_nivel, r.r_label_geo, r.r_nivel_geo, r.r_label_reest, r.r_nivel_reest, r.flg_reest,
    r.ubigeo_inei_nodo, r.ubigeo_formato_inei, r.ubigeo_reniec,
    r.departamento_reniec, r.provincia_reniec, r.distrito_reniec,
    r.flg_nodo, r.flg_concordancia, r.flg_particion, r.nivel_reniec,
    r.flg_regimen, r.tramo_dist, r.zona_exp, r.patron_evento,
    r.dist_am_m, r.dist_ma_m, r.flg_ma_300, r.flg_ma_500, r.flg_ma_1000, r.exp25, r.exp50, r.prec_m, r.flg_fuente
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202605' AND '202607'
)
SELECT
  codmes,
  round(pd_cal, 5) AS pd,
  CASE WHEN punt >= 993 THEN 'G1' WHEN punt >= 972 THEN 'G2' WHEN punt >= 959 THEN 'G3'
       WHEN punt >= 921 THEN 'G4' WHEN punt >= 884 THEN 'G5' WHEN punt >= 850 THEN 'G6'
       ELSE 'GR' END AS grado,
  sub_producto, tipo_ingreso AS tipo, CAST(target_12m AS integer) AS rd12,
  r_label, CAST(r_nivel AS integer) AS r_dir,
  r_label_geo, CAST(r_nivel_geo AS integer) AS r_geo,
  r_label_reest, CAST(r_nivel_reest AS integer) AS r_reest, flg_reest,
  CASE WHEN r_nivel_reest >= 1 THEN 1 ELSE 0 END AS pac,
  ubigeo_inei_nodo AS ubigeo_dom, ubigeo_formato_inei AS ubigeo_geo, ubigeo_reniec,
  substr(ubigeo_inei_nodo, 1, 2) AS depto,
  departamento_reniec, provincia_reniec, distrito_reniec,
  flg_nodo, flg_concordancia, flg_particion, nivel_reniec,
  flg_regimen, tramo_dist, zona_exp, patron_evento,
  round(dist_am_m, 1) AS dist_am_m, round(dist_ma_m, 1) AS dist_ma_m,
  flg_ma_300, flg_ma_500, flg_ma_1000,
  round(exp25, 4) AS exp25, round(exp50, 4) AS exp50, round(prec_m, 1) AS prec_m, flg_fuente
FROM j
