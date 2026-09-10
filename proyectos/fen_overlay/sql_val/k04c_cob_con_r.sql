-- k04c: universo VC 202608 vs mca_bd_reniec_xy_con_r (los que SI recibieron R, antes de la reestructuracion). Compara con el 9.1M de r_reest: si con_r > r_reest, la reestructuracion perdio gente. Read-only, 1 fila
SELECT
  count(*)                                            AS n_univ,
  count(t.key_value)                                  AS n_en_con_r,
  round(100.0 * count(t.key_value) / count(*), 2)     AS pct
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_con_r t ON u.key_value = t.key_value
WHERE u.codmes = '202608'
