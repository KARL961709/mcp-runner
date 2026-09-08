-- j01 altas PP 1 a 1 para el simulador FEN: score DIRECTO (r_nivel domicilio) + GEO (r_nivel_geo) + REESTRUCTURADO (r_nivel_reest), ubigeo del DOMICILIO (ubigeo_inei_nodo, cascada N1/N2/N3) para pegar el s indirecto local, + exposicion fisica y diagnosticos. Mismos joins/filtros que h01
WITH j AS (
  SELECT
    CASE WHEN a.sub_producto='PP_CD' THEN a.puntuacion_modelo_cal_ppcd ELSE a.puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN a.sub_producto='PP_CD' THEN a.prob_modelo_cal_ppcd ELSE a.prob_modelo_cal_ppfacil END AS pd_cal,
    a.codmes, a.sub_producto, a.tipo_ingreso, a.target_12m,
    r.r_nivel, r.r_nivel_geo, r.r_nivel_reest,
    r.ubigeo_inei_nodo, r.ubigeo_formato_inei, r.flg_nodo, r.flg_concordancia,
    r.patron_evento, r.flg_regimen, r.flg_fuente, r.dist_ma_m, r.exp25, r.exp50, r.flg_reest
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
  WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
    AND a.codmes BETWEEN '202301' AND '202507'
)
SELECT
  codmes,
  round(pd_cal, 5) AS pd,
  CASE WHEN punt >= 993 THEN 'G1' WHEN punt >= 972 THEN 'G2' WHEN punt >= 959 THEN 'G3'
       WHEN punt >= 921 THEN 'G4' WHEN punt >= 884 THEN 'G5' WHEN punt >= 850 THEN 'G6'
       ELSE 'GR' END AS grado,
  sub_producto,
  tipo_ingreso AS tipo,
  CAST(target_12m AS integer) AS rd12,
  CAST(r_nivel AS integer) AS r_dir,
  CAST(r_nivel_geo AS integer) AS r_geo,
  CAST(r_nivel_reest AS integer) AS r_reest,
  CASE WHEN r_nivel_reest >= 1 THEN 1 ELSE 0 END AS pac,
  flg_reest, flg_nodo, flg_concordancia,
  ubigeo_inei_nodo AS ubigeo_dom,
  ubigeo_formato_inei AS ubigeo_geo,
  patron_evento, flg_regimen, flg_fuente,
  round(dist_ma_m, 1) AS dist_ma_m,
  round(exp25, 4) AS exp25,
  round(exp50, 4) AS exp50
FROM j
