-- u01 pilot QA 2609 (smoke test fuente v3): grano (n vs n_dist), 0 SIN_NODO, tipo_ingreso poblado. dirty=0 (piloto sin dirty).
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT cod_tip_doc || '|' || key_value) AS n_dist,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS ti_null,
  SUM(CASE WHEN nodo_ppfacil = 'SIN_NODO' THEN 1 ELSE 0 END) AS ppf_sinnodo,
  SUM(CASE WHEN nodo_ec = 'SIN_NODO' THEN 1 ELSE 0 END) AS ec_sinnodo,
  SUM(CASE WHEN nodo_tc = 'SIN_NODO' THEN 1 ELSE 0 END) AS tc_sinnodo,
  ROUND(AVG(pd_raw), 5) AS pd_raw_avg
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_nodos_pilot
GROUP BY codmes
ORDER BY codmes
