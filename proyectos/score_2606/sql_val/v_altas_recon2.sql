-- v_altas_recon2. Reconciliacion CORREGIDA universo vs altas_*_cal:
--   PP comparado sobre SU propio sub_producto (las altas usan 1 nodo por fila -> comparar ppcd sobre filas
--   PP_FACIL daba artefacto). + cuantifica dirty: n_dirty_altas(flg_clean=0) vs n_dirty_univ(flg_dirty LEAN)
--   y n_disagree. EC no usa dirty (por eso calza exacto). Join (tip_doc,key_value,codmes), flg_ibk=1.
WITH u AS (
  SELECT cod_tip_doc, key_value, codmes,
         prob_modelo_cal_ppfacil, prob_modelo_cal_ppcd, prob_modelo_cal_ec, prob_modelo_cal_tcbnk,
         flg_dirty_tc, flg_dirty_pp
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608
)
SELECT modelo, codmes, n_altas, n_match, ROUND(avg_absdiff, 6) AS avg_absdiff, n_exact_5e4,
  ROUND(pd_altas, 5) AS pd_altas, ROUND(pd_univ, 5) AS pd_univ,
  n_dirty_altas, n_dirty_univ, n_disagree
FROM (
  SELECT 'ec' AS modelo, CAST(a.codmes AS varchar) AS codmes, COUNT(*) AS n_altas,
    SUM(CASE WHEN u.prob_modelo_cal_ec IS NOT NULL AND a.prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS n_match,
    AVG(ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal)) AS avg_absdiff,
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal) < 0.0005 THEN 1 ELSE 0 END) AS n_exact_5e4,
    AVG(a.prob_modelo_cal) AS pd_altas, AVG(u.prob_modelo_cal_ec) AS pd_univ,
    SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) AS n_dirty_altas,
    CAST(0 AS bigint) AS n_dirty_univ, CAST(0 AS bigint) AS n_disagree
  FROM disc_model_owner.altas_ec_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'tc', CAST(a.codmes AS varchar), COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_tcbnk IS NOT NULL AND a.prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal) < 0.0005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal), AVG(u.prob_modelo_cal_tcbnk),
    SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_tc = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_tc <> (CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END)
  FROM disc_model_owner.altas_adm_tcbank_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'ppfacil', CAST(a.codmes AS varchar), COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_ppfacil IS NOT NULL AND a.prob_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil) < 0.0005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal_ppfacil), AVG(u.prob_modelo_cal_ppfacil),
    SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_pp = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_pp <> (CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END)
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND a.sub_producto = 'PP_FACIL' AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'ppcd', CAST(a.codmes AS varchar), COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_ppcd IS NOT NULL AND a.prob_modelo_cal_ppcd IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd) < 0.0005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal_ppcd), AVG(u.prob_modelo_cal_ppcd),
    SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_pp = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN u.flg_dirty_pp <> (CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END)
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND a.sub_producto = 'PP_CD' AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
) t
ORDER BY modelo, codmes
