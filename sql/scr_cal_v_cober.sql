-- scr_cal_v_cober.sql | cobertura por campana: n, n con prob_modelo_cal, n con pd_opt_v2, y desglose de fuente V2 (1=bankbn oficial, 2=rebuilt propio). Confirma pd_cal=100% y pd_opt_v2=100% (202608 se llena via rebuilt). Agregado.
SELECT p_codmes,
  COUNT(*) AS n,
  SUM(CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS n_pcal,
  SUM(CASE WHEN pd_opt_v2 IS NOT NULL THEN 1 ELSE 0 END) AS n_v2,
  SUM(CASE WHEN flg_match_v2=1 THEN 1 ELSE 0 END) AS n_bankbn,
  SUM(CASE WHEN flg_match_v2=2 THEN 1 ELSE 0 END) AS n_rebuilt
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
GROUP BY p_codmes ORDER BY p_codmes
