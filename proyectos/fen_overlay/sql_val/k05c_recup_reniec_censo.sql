-- k05c: igual que k05b pero contra mca_reniec_api (fuente alterna). Compara cual master cubre mas de los 3.83M sin geo. Read-only, 1 fila. Join solo por key_value
SELECT
  count(*)           AS n_sin_geo,
  count(m.key_value) AS n_en_mca_reniec_api,
  round(100.0 * count(m.key_value) / count(*), 2) AS pct_recuperable
FROM (
  SELECT u.key_value
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
  WHERE u.codmes = '202608' AND r.key_value IS NULL
) u
LEFT JOIN disc_model_owner.mca_reniec_api m ON u.key_value = m.key_value
