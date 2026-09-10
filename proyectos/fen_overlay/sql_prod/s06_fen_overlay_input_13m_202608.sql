-- s06 fen_overlay_input_13m_202608: overlay COMPLETO de los 12.93M (universo VC 202608), no solo los 9.1M con XY. Para los 3.83M SIN XY reconstruye el R DIRECTO distrital desde su domicilio declarado (e_perm_aws.t_mst_reniec_rsk.cod_ubi_domicilio, formato RENIEC) puenteado a INEI con el diccionario que dan los 9.1M (ubigeo_reniec -> ubigeo_formato_inei) y toma el r_nivel (directo) modal por distrito. Bucket marca el origen (xy_reest fino vs sin_xy_dir distrital vs sin_ubigeo base). CTAS -> parquet (-Bajar). Correr DESPUES de s01,s02. RE-crear: vaciar <S3_DATOS>/fen_overlay_input_13m_202608/
CREATE TABLE disc_model_owner.fen_overlay_input_13m_202608
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_overlay_input_13m_202608/') AS
WITH dist AS (
  SELECT ubigeo_reniec,
         max_by(ubigeo_formato_inei, n) AS ubigeo_inei,
         max_by(r_nivel_int, n)         AS r_dir_distrital
  FROM (
    SELECT ubigeo_reniec, ubigeo_formato_inei, CAST(r_nivel AS integer) AS r_nivel_int, count(*) AS n
    FROM disc_model_owner.mca_bd_reniec_xy_r_reest
    WHERE ubigeo_reniec IS NOT NULL AND length(ubigeo_reniec) = 6 AND ubigeo_formato_inei IS NOT NULL
    GROUP BY ubigeo_reniec, ubigeo_formato_inei, CAST(r_nivel AS integer)
  )
  GROUP BY ubigeo_reniec
)
SELECT
  u.key_value, u.codmes, u.tipo_ingreso,
  u.prob_modelo_cal_ppfacil AS pd_ppfacil,
  u.prob_modelo_cal_ppcd    AS pd_ppcd,
  CASE WHEN u.puntuacion_modelo_cal_ppfacil>=993 THEN 'G1' WHEN u.puntuacion_modelo_cal_ppfacil>=972 THEN 'G2'
       WHEN u.puntuacion_modelo_cal_ppfacil>=959 THEN 'G3' WHEN u.puntuacion_modelo_cal_ppfacil>=921 THEN 'G4'
       WHEN u.puntuacion_modelo_cal_ppfacil>=884 THEN 'G5' WHEN u.puntuacion_modelo_cal_ppfacil>=850 THEN 'G6'
       ELSE 'GR' END AS grado,
  CASE WHEN r.key_value IS NOT NULL THEN 'xy_reest'
       WHEN d.ubigeo_reniec IS NOT NULL THEN 'sin_xy_dir'
       ELSE 'sin_ubigeo' END AS bucket,
  CASE WHEN r.key_value IS NOT NULL THEN CAST(r.r_nivel_reest AS integer)
       WHEN d.ubigeo_reniec IS NOT NULL THEN d.r_dir_distrital
       ELSE 0 END AS r_fis,
  CASE WHEN r.key_value IS NOT NULL THEN (CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END)
       WHEN d.ubigeo_reniec IS NOT NULL THEN (CASE WHEN d.r_dir_distrital>=1 THEN 1 ELSE 0 END)
       ELSE 0 END AS pac,
  coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei) AS ubigeo_dom,
  substr(coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei), 1, 2) AS depto,
  s.s_total,
  coalesce(ibk.ibk_c_pea, 0) AS ibk_centrado,
  coalesce(ibk.resil_pea, 0) AS resiliente
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
LEFT JOIN e_perm_aws.t_mst_reniec_rsk b ON u.key_value = b.key_value AND r.key_value IS NULL
LEFT JOIN dist d ON b.cod_ubi_domicilio = d.ubigeo_reniec
LEFT JOIN disc_model_owner.fen_s_indirecto s ON coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei) = s.ubigeo
LEFT JOIN disc_model_owner.fen_ibk_plus ibk ON substr(coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei), 1, 2) = ibk.depto
WHERE u.codmes = '202608'
