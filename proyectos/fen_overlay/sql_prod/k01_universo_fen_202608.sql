-- k01 universo FEN 202608: los ~14M scoreados (universo VC, proyecto score_2606) del codmes 202608 unidos al score FEN COMPLETO de reniec (mca_bd_reniec_xy_r_reest: directo + geo + REESTRUCTURADO + fisico + ubigeos + cascada). CTAS a parquet -> se BAJA con -Bajar. Todo el score sale de reniec (unica fuente). Correr de a UNO con -Only k01_universo_fen_202608. RE-crear: vaciar antes <S3_DATOS>/fen_universo_202608/
CREATE TABLE disc_model_owner.fen_universo_202608_cal
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_universo_202608/') AS
SELECT
  -- universo scoreado (PP Facil / CD)
  u.codmes, u.key_value, u.tipo_ingreso, u.nodo,
  u.prob_modelo_cal_ppfacil, u.prob_modelo_cal_ppcd,
  u.puntuacion_modelo_cal_ppfacil, u.puntuacion_modelo_cal_ppcd,
  -- SCORE DIRECTO (domicilio declarado) y GEO (donde cae el X,Y)
  r.r_label, CAST(r.r_nivel AS integer) AS r_dir,
  r.r_label_geo, CAST(r.r_nivel_geo AS integer) AS r_geo,
  -- SCORE REESTRUCTURADO (campo de uso)
  r.r_label_reest, CAST(r.r_nivel_reest AS integer) AS r_reest, r.flg_reest,
  CASE WHEN r.r_nivel_reest >= 1 THEN 1 ELSE 0 END AS pac,
  -- ubigeos (domicilio resuelto por cascada / geometrico / crudo RENIEC) + nombres + diagnosticos de cascada
  r.ubigeo_inei_nodo AS ubigeo_dom, r.ubigeo_formato_inei AS ubigeo_geo, r.ubigeo_reniec,
  substr(r.ubigeo_inei_nodo, 1, 2) AS depto,
  r.departamento_reniec, r.provincia_reniec, r.distrito_reniec,
  r.flg_nodo, r.flg_concordancia, r.flg_particion, r.nivel_reniec,
  -- REESTRUCTURACION (regimen y tramos) + patron de eventos
  r.flg_regimen, r.tramo_dist, r.zona_exp, r.patron_evento,
  -- FISICO / PELIGRO (distancia y exposicion) + fuente/precision
  round(r.dist_am_m, 1) AS dist_am_m, round(r.dist_ma_m, 1) AS dist_ma_m,
  r.flg_ma_300, r.flg_ma_500, r.flg_ma_1000,
  round(r.exp25, 4) AS exp25, round(r.exp50, 4) AS exp50,
  round(r.prec_m, 1) AS prec_m, r.flg_fuente
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
WHERE u.codmes = '202608'
