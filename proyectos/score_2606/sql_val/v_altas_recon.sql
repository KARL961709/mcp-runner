-- v_altas_recon. Reconciliacion universo vs altas_*_cal DESPLEGADAS (mismas personas admitidas IBK).
--   Join (tip_doc=cod_tip_doc, key_value, codmes). prob_modelo_cal universo debe ~= altas (misma cadena).
--   n_match/n_altas = cobertura . avg/max_absdiff ~0 = motor identico . n_exact(<5e-4) = calce.
--   EC no tiene dirty -> debe calzar exacto. TC/PP: el tail sale del dirty LEAN(clasif>CPP) vs flg_clean completo.
WITH u AS (
  SELECT cod_tip_doc, key_value, codmes,
         prob_modelo_cal_ppfacil, prob_modelo_cal_ppcd, prob_modelo_cal_ec, prob_modelo_cal_tcbnk
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608
)
SELECT modelo, codmes, n_altas, n_match,
  ROUND(avg_absdiff, 6) AS avg_absdiff, ROUND(max_absdiff, 6) AS max_absdiff,
  n_exact_5e4, n_le_5e3, ROUND(pd_altas, 5) AS pd_altas, ROUND(pd_univ, 5) AS pd_univ
FROM (
  SELECT 'ec' AS modelo, CAST(a.codmes AS varchar) AS codmes,
    COUNT(*) AS n_altas,
    SUM(CASE WHEN u.prob_modelo_cal_ec IS NOT NULL AND a.prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS n_match,
    AVG(ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal)) AS avg_absdiff,
    MAX(ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal)) AS max_absdiff,
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal) < 0.0005 THEN 1 ELSE 0 END) AS n_exact_5e4,
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ec - a.prob_modelo_cal) < 0.005 THEN 1 ELSE 0 END) AS n_le_5e3,
    AVG(a.prob_modelo_cal) AS pd_altas, AVG(u.prob_modelo_cal_ec) AS pd_univ
  FROM disc_model_owner.altas_ec_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'tc', CAST(a.codmes AS varchar),
    COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_tcbnk IS NOT NULL AND a.prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal)),
    MAX(ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal) < 0.0005 THEN 1 ELSE 0 END),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_tcbnk - a.prob_modelo_cal) < 0.005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal), AVG(u.prob_modelo_cal_tcbnk)
  FROM disc_model_owner.altas_adm_tcbank_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'ppfacil', CAST(a.codmes AS varchar),
    COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_ppfacil IS NOT NULL AND a.prob_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil)),
    MAX(ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil) < 0.0005 THEN 1 ELSE 0 END),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppfacil - a.prob_modelo_cal_ppfacil) < 0.005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal_ppfacil), AVG(u.prob_modelo_cal_ppfacil)
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
  UNION ALL
  SELECT 'ppcd', CAST(a.codmes AS varchar),
    COUNT(*),
    SUM(CASE WHEN u.prob_modelo_cal_ppcd IS NOT NULL AND a.prob_modelo_cal_ppcd IS NOT NULL THEN 1 ELSE 0 END),
    AVG(ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd)),
    MAX(ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd)),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd) < 0.0005 THEN 1 ELSE 0 END),
    SUM(CASE WHEN ABS(u.prob_modelo_cal_ppcd - a.prob_modelo_cal_ppcd) < 0.005 THEN 1 ELSE 0 END),
    AVG(a.prob_modelo_cal_ppcd), AVG(u.prob_modelo_cal_ppcd)
  FROM disc_model_owner.altas_adm_pp_cdpp_cal a
  LEFT JOIN u ON u.cod_tip_doc = CAST(a.tip_doc AS varchar) AND u.key_value = a.key_value AND u.codmes = CAST(a.codmes AS varchar)
  WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202608'
  GROUP BY CAST(a.codmes AS varchar)
) t
ORDER BY modelo, codmes
