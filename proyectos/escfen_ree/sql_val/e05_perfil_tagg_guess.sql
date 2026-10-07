-- e05. perfil global t_agg_comppree_rsk (FREEZE) [schema TENTATIVO: cod_tip_doc/key_value/prob_modelo_cal]
--   try_cast evita fallo duro si prob_modelo_cal es varchar o vacio. Si fallan los nombres, e01 da la verdad.
SELECT COUNT(*) AS n,
  COUNT(DISTINCT cod_tip_doc || '|' || key_value) AS n_dist_key,
  ROUND(AVG(try_cast(prob_modelo_cal AS DOUBLE)), 5) AS pit_freeze,
  SUM(CASE WHEN try_cast(prob_modelo_cal AS DOUBLE) IS NULL THEN 1 ELSE 0 END) AS n_pit_null
FROM e_perm_aws.t_agg_comppree_rsk
