-- d_dirty_vs_altas. Valida el dirty reconstruido (..._dirty_pilot, 202607) vs el flg_clean DESPLEGADO (altas), por producto.
--   agree/n_match ~99% = la cascada por producto reproduce el dirty desplegado. miss = brazos faltantes. extra = sobre-marca.
--   TC: flg_dirty_tc vs (altas_adm_tcbank_cal.flg_clean=0). PP: flg_dirty_pp vs (altas_adm_pp_cdpp_cal.flg_clean=0). flg_ibk=1, 202607.
WITH dp AS (
  SELECT cod_tip_doc, key_value, flg_dirty_tc, flg_dirty_pp
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_dirty_pilot
)
SELECT 'tc' AS modelo, COUNT(*) AS n_altas,
  SUM(CASE WHEN dp.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_match,
  SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) AS n_dep_dirty,
  SUM(COALESCE(dp.flg_dirty_tc, 0)) AS n_uni_dirty,
  SUM(CASE WHEN (CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) = COALESCE(dp.flg_dirty_tc, 0) THEN 1 ELSE 0 END) AS n_agree,
  SUM(CASE WHEN a.flg_clean = 0 AND COALESCE(dp.flg_dirty_tc, 0) = 0 THEN 1 ELSE 0 END) AS n_miss,
  SUM(CASE WHEN a.flg_clean <> 0 AND COALESCE(dp.flg_dirty_tc, 0) = 1 THEN 1 ELSE 0 END) AS n_extra
FROM disc_model_owner.altas_adm_tcbank_cal a
LEFT JOIN dp ON dp.cod_tip_doc = CAST(a.tip_doc AS varchar) AND dp.key_value = a.key_value
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) = '202607'
UNION ALL
SELECT 'pp', COUNT(*),
  SUM(CASE WHEN dp.key_value IS NOT NULL THEN 1 ELSE 0 END),
  SUM(CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END),
  SUM(COALESCE(dp.flg_dirty_pp, 0)),
  SUM(CASE WHEN (CASE WHEN a.flg_clean = 0 THEN 1 ELSE 0 END) = COALESCE(dp.flg_dirty_pp, 0) THEN 1 ELSE 0 END),
  SUM(CASE WHEN a.flg_clean = 0 AND COALESCE(dp.flg_dirty_pp, 0) = 0 THEN 1 ELSE 0 END),
  SUM(CASE WHEN a.flg_clean <> 0 AND COALESCE(dp.flg_dirty_pp, 0) = 1 THEN 1 ELSE 0 END)
FROM disc_model_owner.altas_adm_pp_cdpp_cal a
LEFT JOIN dp ON dp.cod_tip_doc = CAST(a.tip_doc AS varchar) AND dp.key_value = a.key_value
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) = '202607'
