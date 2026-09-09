-- s03b fen_overlay_altas_202605_202607: tabla CONSOLIDADA del overlay FEN para las ALTAS recientes (libro vigente a estresar, codmes 202605-202607). Misma estructura que s03 (PEA) pero fuente = altas_adm_pp_cdpp_cal y IBK+ = ibk_c_altas (avg 202605-202607, ventana de las altas). Une altas + mca_bd_reniec_xy_r_reest (score directo/geo/REEST + fisico + ubigeo domicilio) + fen_s_indirecto (s) + fen_ibk_plus (IBK+ centrado por depto). rd12 (target_12m) INMADURO (no valida, se estresa). Poblacion clean IBK. CTAS -> parquet (-Bajar). Correr DESPUES de s01, s02. Todo el score sale de mca_bd_reniec_xy_r_reest
CREATE TABLE disc_model_owner.fen_overlay_altas_202605_202607
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_overlay_altas_202605_202607/') AS
WITH a AS (
  SELECT
    key_value, codmes, tipo_ingreso, nodo, sub_producto, target_12m,
    CASE WHEN sub_producto='PP_CD' THEN puntuacion_modelo_cal_ppcd ELSE puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN sub_producto='PP_CD' THEN prob_modelo_cal_ppcd       ELSE prob_modelo_cal_ppfacil       END AS pd
  FROM disc_model_owner.altas_adm_pp_cdpp_cal
  WHERE flg_ibk = 1 AND flg_clean = 1 AND sub_producto IN ('PP_CD','PP_FACIL')
    AND codmes BETWEEN '202605' AND '202607'
)
SELECT
  a.key_value, a.codmes, a.tipo_ingreso, a.nodo, a.sub_producto,
  round(a.pd, 5) AS pd,
  CASE WHEN a.punt>=993 THEN 'G1' WHEN a.punt>=972 THEN 'G2' WHEN a.punt>=959 THEN 'G3'
       WHEN a.punt>=921 THEN 'G4' WHEN a.punt>=884 THEN 'G5' WHEN a.punt>=850 THEN 'G6'
       ELSE 'GR' END AS grado,
  CAST(a.target_12m AS integer) AS rd12,
  CAST(r.r_nivel AS integer) AS r_dir, CAST(r.r_nivel_geo AS integer) AS r_geo, CAST(r.r_nivel_reest AS integer) AS r_reest,
  CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END AS pac,
  r.ubigeo_inei_nodo AS ubigeo_dom, substr(r.ubigeo_inei_nodo,1,2) AS depto,
  round(r.dist_ma_m,1) AS dist_ma_m, round(r.exp25,4) AS exp25, round(r.exp50,4) AS exp50,
  r.patron_evento, r.flg_regimen,
  s.s_total, s.nivel AS s_nivel,
  ibk.ibk_altas AS ibk_plus, coalesce(ibk.ibk_c_altas, 0) AS ibk_centrado, coalesce(ibk.resil_altas, 0) AS resiliente
FROM a
JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
LEFT JOIN disc_model_owner.fen_s_indirecto s ON r.ubigeo_inei_nodo = s.ubigeo
LEFT JOIN disc_model_owner.fen_ibk_plus ibk ON substr(r.ubigeo_inei_nodo,1,2) = ibk.depto
