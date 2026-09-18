-- QA[2] todo flg_cruce=1 => todas las PD y grupo no nulos (0 excepciones)
SELECT 'nulos_bank' AS chk, COUNT(*) AS n_bank,
  SUM(CASE WHEN pd_ttc IS NULL THEN 1 ELSE 0 END) AS ttc_null,
  SUM(CASE WHEN pd_pit IS NULL THEN 1 ELSE 0 END) AS pit_null,
  SUM(CASE WHEN pd_pit_final IS NULL THEN 1 ELSE 0 END) AS pitf_null,
  SUM(CASE WHEN grupo_cal IS NULL THEN 1 ELSE 0 END) AS grupo_null,
  SUM(CASE WHEN pd_v2_esc_opt IS NULL THEN 1 ELSE 0 END) AS v2_null
FROM disc_model_owner.b46029_desemb_maestra_202609 WHERE flg_cruce=1
