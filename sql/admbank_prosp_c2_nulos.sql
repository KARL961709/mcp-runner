-- QA[2] nulos en PDs/grupos (deben ser 0)
SELECT COUNT(*) AS n, SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS pdcal_null, SUM(CASE WHEN pd_v2_esc_opt IS NULL THEN 1 ELSE 0 END) AS v2_null,
  SUM(CASE WHEN grupos_cal IS NULL THEN 1 ELSE 0 END) AS gcal_null, SUM(CASE WHEN grupos_ant IS NULL THEN 1 ELSE 0 END) AS gant_null
FROM disc_model_owner.admbank_prosp_202608
