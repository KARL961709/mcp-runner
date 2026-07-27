-- ============================================================================
-- G2. LA HISTORIA 2019-2021 SOLO SOBREVIVE EN enr_comp_pp_ree_cal.
--     Serie mensual del perimetro reenganche para decidir si se conserva,
--     se reconstruye desde las fuentes crudas, o se recorta la ventana de LRA.
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                                              AS codmes,
  COUNT(*)                                                                             AS n,
  SUM(CASE WHEN dsc_flg_malo_12m_60 IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END) AS n_po,
  SUM(CASE WHEN dsc_flg_malo_12m_60 = 'MALO'          THEN 1 ELSE 0 END)               AS n_malo,
  SUM(CASE WHEN dsc_flg_malo_12m_60 = 'INDETERMINADO' THEN 1 ELSE 0 END)               AS n_indet,
  SUM(CASE WHEN dsc_flg_malo_12m_60 = 'INSUFICIENTE'  THEN 1 ELSE 0 END)               AS n_insuf,
  COUNT(*) - SUM(CASE WHEN dsc_flg_malo_12m_60 IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END) AS n_ramas_duras,
  ROUND(100.0 * SUM(CASE WHEN dsc_flg_malo_12m_60 = 'MALO' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN dsc_flg_malo_12m_60 IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END), 0), 4) AS rd12_pct
FROM disc_model_owner.enr_comp_pp_ree_cal
WHERE flg_calib = 1
  AND CAST(codmes AS INT) <= 202112
GROUP BY 1
ORDER BY 1
