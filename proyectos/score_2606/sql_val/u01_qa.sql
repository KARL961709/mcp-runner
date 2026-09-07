-- u01 full QA por codmes: grano (n vs n_dist), 0 SIN_NODO por producto, composicion nodo/tipo_ingreso/dirty.
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT cod_tip_doc || '|' || key_value) AS n_dist,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS ti_null,
  ROUND(AVG(CAST(flg_dirty_tc AS double)), 4) AS dirty_rate,
  SUM(CASE WHEN nodo_ppfacil = 'SIN_NODO' THEN 1 ELSE 0 END) AS ppf_sinnodo,
  SUM(CASE WHEN nodo_ppcd = 'SIN_NODO' THEN 1 ELSE 0 END) AS ppcd_sinnodo,
  SUM(CASE WHEN nodo_ec = 'SIN_NODO' THEN 1 ELSE 0 END) AS ec_sinnodo,
  SUM(CASE WHEN nodo_tc = 'SIN_NODO' THEN 1 ELSE 0 END) AS tc_sinnodo
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_nodos
GROUP BY codmes
ORDER BY codmes
