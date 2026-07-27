-- ============================================================================
-- F2b. ARTEFACTO enr_comp_pp_ree_cal_rev_3 (el unico que trae las columnas base
--      flg_rfnc_12m / flg_cstg_12m / max_dm_12m) -> permite el contrafactual E7.
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                                        AS anio,
  COUNT(*)                                                                                     AS n_universo,
  SUM(CASE WHEN flg_reenganche = 1 THEN 1 ELSE 0 END)                                          AS n_ree,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END) AS n_ree_po,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 = 'MALO' THEN 1 ELSE 0 END)         AS n_ree_casc,
  SUM(CASE WHEN flg_reenganche = 1 AND (flg_rfnc_12m = 1 OR flg_cstg_12m = 1 OR max_dm_12m > 60) THEN 1 ELSE 0 END) AS n_ree_red,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 = 'MALO' AND NOT (flg_rfnc_12m = 1 OR flg_cstg_12m = 1 OR max_dm_12m > 60) THEN 1 ELSE 0 END) AS n_10,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 <> 'MALO' AND (flg_rfnc_12m = 1 OR flg_cstg_12m = 1 OR max_dm_12m > 60) THEN 1 ELSE 0 END) AS n_01,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 = 'INSUFICIENTE' THEN 1 ELSE 0 END) AS n_insuf,
  SUM(CASE WHEN flg_reenganche = 1 AND dsc_flg_malo_12m_60 = 'INDETERMINADO' THEN 1 ELSE 0 END) AS n_indet
FROM disc_model_owner.enr_comp_pp_ree_cal_rev_3
GROUP BY 1
ORDER BY 1
