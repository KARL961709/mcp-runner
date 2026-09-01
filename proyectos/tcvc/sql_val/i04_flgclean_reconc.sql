-- i04. H2 reconciliacion: dominio de flg_clean (ojo 99) x flg_calib x flg_ibk.
SELECT flg_clean, flg_calib, flg_ibk, COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pdraw,
  SUM(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_mat12
FROM disc_model_owner.ds_adm_tcbank_cal
GROUP BY flg_clean, flg_calib, flg_ibk
ORDER BY flg_clean, flg_calib, flg_ibk