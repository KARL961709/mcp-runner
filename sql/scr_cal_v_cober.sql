-- scr_cal_v_cober | cobertura por campana: n filas, n con prob_modelo_cal, n con pd_opt_v2 (confirma pd_cal=100%, pd_v2 falta solo 202608). Agregado.
SELECT p_codmes,
  COUNT(*) AS n,
  SUM(CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS n_pcal,
  SUM(flg_match_v2) AS n_v2opt
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
GROUP BY p_codmes ORDER BY p_codmes
