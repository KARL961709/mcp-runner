-- u01 pilot QA: valida el enriquecimiento en la muestra (nodos, tipo_ingreso, dirty, SIN_NODO).
SELECT COUNT(*) AS n,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS ti_null,
  SUM(CASE WHEN tipo_ingreso = 'DEP' THEN 1 ELSE 0 END) AS ti_dep,
  ROUND(AVG(CAST(flg_dirty_tc AS double)), 4) AS dirty_rate,
  SUM(CASE WHEN nodo_ec = 'SIN_NODO' THEN 1 ELSE 0 END) AS ec_sinnodo,
  SUM(CASE WHEN nodo_ec = 'NODO 1' THEN 1 ELSE 0 END) AS ec_n1,
  SUM(CASE WHEN nodo_ec = 'NODO 3' THEN 1 ELSE 0 END) AS ec_n3,
  SUM(CASE WHEN nodo_tc = 'SIN_NODO' THEN 1 ELSE 0 END) AS tc_sinnodo
FROM disc_model_owner.univ_vc_nodos_pilot
