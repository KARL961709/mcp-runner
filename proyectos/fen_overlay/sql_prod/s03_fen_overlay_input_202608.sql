-- s03 fen_overlay_input_202608: tabla CONSOLIDADA del overlay FEN (universo 14M, 202608) = TODO lo necesario para dinamizar el artifact, por cliente. Une el universo scoreado + mca_bd_reniec_xy_r_reest (score directo/geo/REEST + fisico + ubigeo domicilio) + fen_s_indirecto (s por ubigeo domicilio) + fen_ibk_plus (valor IBK+ centrado depto-nac, mes PEA 202608 = proyeccion, columna ibk_c_pea). CTAS -> parquet (-Bajar). Correr DESPUES de s01, s02. RE-crear: vaciar <S3_DATOS>/fen_overlay_input_202608/
CREATE TABLE disc_model_owner.fen_overlay_input_202608
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_overlay_input_202608/') AS
SELECT
  u.key_value, u.codmes, u.tipo_ingreso, u.nodo,
  u.prob_modelo_cal_ppfacil AS pd_ppfacil,
  u.prob_modelo_cal_ppcd    AS pd_ppcd,
  CASE WHEN u.puntuacion_modelo_cal_ppfacil>=993 THEN 'G1' WHEN u.puntuacion_modelo_cal_ppfacil>=972 THEN 'G2'
       WHEN u.puntuacion_modelo_cal_ppfacil>=959 THEN 'G3' WHEN u.puntuacion_modelo_cal_ppfacil>=921 THEN 'G4'
       WHEN u.puntuacion_modelo_cal_ppfacil>=884 THEN 'G5' WHEN u.puntuacion_modelo_cal_ppfacil>=850 THEN 'G6'
       ELSE 'GR' END AS grado,
  -- score directo/geo/REESTRUCTURADO (mca_bd_reniec_xy_r_reest)
  CAST(r.r_nivel AS integer) AS r_dir, CAST(r.r_nivel_geo AS integer) AS r_geo, CAST(r.r_nivel_reest AS integer) AS r_reest,
  CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END AS pac,
  r.ubigeo_inei_nodo AS ubigeo_dom, substr(r.ubigeo_inei_nodo,1,2) AS depto,
  round(r.dist_ma_m,1) AS dist_ma_m, round(r.exp25,4) AS exp25, round(r.exp50,4) AS exp50,
  r.patron_evento, r.flg_regimen,
  -- score indirecto s (fen_s_indirecto, por ubigeo domicilio)
  s.s_total, s.nivel AS s_nivel,
  -- resiliencia IBK+ (fen_ibk_plus, por depto): desvio de su propia normal gated por Yaku-2023, sin dato -> 0 (peor caso, nunca resiliente)
  ibk.ibk_pea AS ibk_plus, coalesce(ibk.ibk_c_pea, 0) AS ibk_centrado, coalesce(ibk.resil_pea, 0) AS resiliente
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
LEFT JOIN disc_model_owner.fen_s_indirecto s ON r.ubigeo_inei_nodo = s.ubigeo
LEFT JOIN disc_model_owner.fen_ibk_plus ibk ON substr(r.ubigeo_inei_nodo,1,2) = ibk.depto
WHERE u.codmes = '202608'
