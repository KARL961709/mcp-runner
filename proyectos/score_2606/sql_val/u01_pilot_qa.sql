-- u01 pilot QA: 0 SIN_NODO + grano (n vs n_dist) + composicion (nodos/tipo_ingreso/dirty).
SELECT COUNT(*) AS n,
  COUNT(DISTINCT cod_tip_doc || '|' || key_value) AS n_dist,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS ti_null,
  SUM(CASE WHEN tipo_ingreso = 'DEP' THEN 1 ELSE 0 END) AS ti_dep,
  ROUND(AVG(CAST(flg_dirty_tc AS double)), 4) AS dirty_rate,
  SUM(CASE WHEN nodo_ec = 'SIN_NODO' THEN 1 ELSE 0 END) AS ec_sinnodo,
  SUM(CASE WHEN nodo_ec = 'NODO 1' THEN 1 ELSE 0 END) AS ec_n1,
  SUM(CASE WHEN nodo_ec = 'NODO 3' THEN 1 ELSE 0 END) AS ec_n3,
  SUM(CASE WHEN nodo_tc = 'SIN_NODO' THEN 1 ELSE 0 END) AS tc_sinnodo
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_nodos_pilot
