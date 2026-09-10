-- k05b: de los 3.83M del universo VC 202608 SIN XY geo (no cruzan r_reest), cuantos existen en t_mst_reniec_rsk_api (master RENIEC). Si ~3.83M -> tienen registro RENIEC y (probable) ubigeo declarado -> R directo distrital RECUPERABLE, subimos cobertura hacia ~13M. Join solo por key_value (seguro; si la tabla no tiene key_value, k05a lo dice y esta falla sin tumbar al resto). Read-only, 1 fila
SELECT
  count(*)           AS n_sin_geo,
  count(m.key_value) AS n_en_reniec_master,
  round(100.0 * count(m.key_value) / count(*), 2) AS pct_recuperable
FROM (
  SELECT u.key_value
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
  WHERE u.codmes = '202608' AND r.key_value IS NULL
) u
LEFT JOIN disc_model_owner.t_mst_reniec_rsk_api m ON u.key_value = m.key_value
