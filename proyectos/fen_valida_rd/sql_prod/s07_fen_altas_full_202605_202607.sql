-- s07 fen_altas_full_202605_202607: libro de altas recientes COMPLETO (19539, no solo los 17809 con XY). Espejo del s06 (PEA) pero fuente altas_adm_pp_cdpp_cal e IBK+ = ibk_c_altas (como s03b). Los sin XY (1730) reciben R DIRECTO distrital desde cod_ubi_domicilio (e_perm_aws.t_mst_reniec_rsk, RENIEC) puenteado a INEI con el dict de los 9.1M + r_nivel directo modal por distrito. bucket marca xy_reest / sin_xy_dir / sin_ubigeo. rd12 INMADURO (no valida). CTAS -> parquet. Correr DESPUES de s01,s02. RE-crear: vaciar <S3_DATOS>/fen_altas_full_202605_202607/
CREATE TABLE disc_model_owner.fen_altas_full_202605_202607
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_altas_full_202605_202607/') AS
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
),
a AS (
  SELECT key_value, codmes, tipo_ingreso, sub_producto, target_12m,
    CASE WHEN sub_producto='PP_CD' THEN puntuacion_modelo_cal_ppcd ELSE puntuacion_modelo_cal_ppfacil END AS punt,
    CASE WHEN sub_producto='PP_CD' THEN prob_modelo_cal_ppcd       ELSE prob_modelo_cal_ppfacil       END AS pd
  FROM disc_model_owner.altas_adm_pp_cdpp_cal
  WHERE flg_ibk = 1 AND flg_clean = 1 AND sub_producto IN ('PP_CD','PP_FACIL')
    AND codmes BETWEEN '202605' AND '202607'
)
SELECT
  a.key_value, a.codmes, a.tipo_ingreso, a.sub_producto,
  round(a.pd, 5) AS pd,
  CASE WHEN a.punt>=993 THEN 'G1' WHEN a.punt>=972 THEN 'G2' WHEN a.punt>=959 THEN 'G3'
       WHEN a.punt>=921 THEN 'G4' WHEN a.punt>=884 THEN 'G5' WHEN a.punt>=850 THEN 'G6'
       ELSE 'GR' END AS grado,
  CAST(a.target_12m AS integer) AS rd12,
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
  coalesce(ibk.ibk_c_altas, 0) AS ibk_centrado,
  coalesce(ibk.resil_altas, 0) AS resiliente
FROM a
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
LEFT JOIN e_perm_aws.t_mst_reniec_rsk b ON a.key_value = b.key_value AND r.key_value IS NULL
LEFT JOIN dist d ON b.cod_ubi_domicilio = d.ubigeo_reniec
LEFT JOIN disc_model_owner.fen_s_indirecto s ON coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei) = s.ubigeo
LEFT JOIN disc_model_owner.fen_ibk_plus ibk ON substr(coalesce(r.ubigeo_inei_nodo, d.ubigeo_inei), 1, 2) = ibk.depto
