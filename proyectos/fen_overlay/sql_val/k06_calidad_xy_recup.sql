-- k06: de los 3.83M sin r_reest que SI estan en t_mst_reniec_rsk_api, mide la CALIDAD de su XY para saber cuantos son recuperables via point-in-polygon a distrito. Abre por flg_xy_sospechoso x prec_tier + cuenta XY no-nulo. Si el grueso tiene XY no sospechoso y prec_tier decente -> recuperables limpios, el resto es XY dudoso (decision MRM). Read-only, pocas filas
SELECT
  m.flg_xy_sospechoso,
  m.prec_tier,
  count(*)                                                                      AS n,
  sum(CASE WHEN m.lat_final IS NOT NULL AND m.lon_final IS NOT NULL THEN 1 ELSE 0 END) AS n_con_xy
FROM (
  SELECT u.key_value
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON u.key_value = r.key_value
  WHERE u.codmes = '202608' AND r.key_value IS NULL
) u
JOIN disc_model_owner.t_mst_reniec_rsk_api m ON u.key_value = m.key_value
GROUP BY m.flg_xy_sospechoso, m.prec_tier
ORDER BY m.flg_xy_sospechoso, m.prec_tier
