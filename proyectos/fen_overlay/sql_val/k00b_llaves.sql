-- k00b llaves: mide el FORMATO de key_value en las DOS tablas (universo 202608 vs reniec) y la COBERTURA del join, ANTES del CTAS de 14M. Regla del banco: identidad por CODIGO -> si las llaves difieren en length/formato, el join miente en silencio (como el ubigeo RENIEC crudo). Read-only. pct_match debe ser ALTO; si es bajo, el formato de key_value no calza y hay que puentear
SELECT
  count(*)                                   AS n_univ_202608,
  count(r.key_value)                         AS n_match_reniec,
  round(100.0 * count(r.key_value) / count(*), 2) AS pct_match,
  min(length(u.key_value))                   AS ulen_min,
  max(length(u.key_value))                   AS ulen_max,
  min(length(r.key_value))                   AS rlen_min,
  max(length(r.key_value))                   AS rlen_max
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
WHERE u.codmes = '202608'
