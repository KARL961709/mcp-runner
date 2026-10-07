-- e03. perfil scr_stk_ree_pp_cal_202610: cobertura codmes, grano, pd_raw/pit/f_t, segmento
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT tip_doc || '|' || key_value) AS n_dist,
  ROUND(AVG(probabilidad), 5) AS pd_raw,
  ROUND(AVG(prob_modelo_cal), 5) AS pit,
  ROUND(AVG(trf_f_t), 6) AS f_t,
  SUM(CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 1 ELSE 0 END) AS n_dep,
  SUM(CASE WHEN CAST(trf_falla_sin_tipo_ingreso AS INTEGER) = 1 THEN 1 ELSE 0 END) AS n_sin_ti
FROM disc_model_owner.scr_stk_ree_pp_cal_202610
GROUP BY codmes
ORDER BY codmes
