-- k07c: cobertura de los 3.83M sin r_reest en e_perm_aws.t_mst_reniec_rsk (join por key_value). Si ~3.83M cruzan y traen ubigeo declarado no nulo, el r_dir distrital es RECUPERABLE para completar los 13M. Read-only, 1 fila. Si la base no tiene key_value el join da 0 y k07b muestra la llave real
SELECT
  count(*)           AS n_sin_geo,
  count(m.key_value) AS n_en_base_reniec,
  round(100.0 * count(m.key_value) / count(*), 2) AS pct
FROM (
  SELECT u.key_value
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
  WHERE u.codmes = '202608' AND r.key_value IS NULL
) u
LEFT JOIN e_perm_aws.t_mst_reniec_rsk m ON u.key_value = m.key_value
