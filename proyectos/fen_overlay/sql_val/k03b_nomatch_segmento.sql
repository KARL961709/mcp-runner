-- k03b: el universo VC 202608 que NO cruza reniec_xy_r_reest, abierto por tipo_ingreso x nodo. Si el faltante se concentra en un segmento (p.ej. un nodo) es pista de recuperable, si es transversal es cobertura de geolocalizacion. Read-only, pocas filas (LEFT JOIN, cuenta match vs no-match)
SELECT
  u.tipo_ingreso,
  u.nodo,
  count(*)                                                      AS n_univ,
  count(r.key_value)                                            AS n_match,
  count(*) - count(r.key_value)                                 AS n_nomatch,
  round(100.0 * (count(*) - count(r.key_value)) / count(*), 2)  AS pct_nomatch
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
WHERE u.codmes = '202608'
GROUP BY u.tipo_ingreso, u.nodo
ORDER BY u.tipo_ingreso, u.nodo
