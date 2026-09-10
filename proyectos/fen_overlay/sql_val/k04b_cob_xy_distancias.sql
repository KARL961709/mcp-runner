-- k04b: de los 12.93M del universo VC 202608, cuantos estan en mca_bd_reniec_xy_distancias (XY geolocalizado, ANTES del split con_r/sin_r). Si ~12.9M -> casi todos tienen geo y el hueco de r_reest es solo asignacion de R (RECUPERABLE). Si ~9.1M -> techo de geo real. Read-only, 1 fila
SELECT
  count(*)                                            AS n_univ,
  count(t.key_value)                                  AS n_en_xy_distancias,
  round(100.0 * count(t.key_value) / count(*), 2)     AS pct
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_distancias t ON u.key_value = t.key_value
WHERE u.codmes = '202608'
