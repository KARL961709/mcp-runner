-- g05 verifica si pp_vc_ds_po_origpp trae SS.FF. (todas las entidades) o solo IBK (00002), y el rango de codmes con target maduro. Decide si el analisis RD-zona se puede correr a nivel sistema (mas n, menos seleccion de admision). READ-ONLY.
SELECT
  cod_instit_financiera,
  count(*)                                                        AS n,
  sum(CASE WHEN flg_calib_rd = 1 THEN 1 ELSE 0 END)               AS n_calib_rd,
  sum(CASE WHEN flg_target_pp_12m IS NOT NULL THEN 1 ELSE 0 END)  AS n_target_maduro,
  min(codmes)                                                     AS cm_min,
  max(CASE WHEN flg_target_pp_12m IS NOT NULL THEN codmes END)    AS cm_max_maduro
FROM disc_model_owner.pp_vc_ds_po_origpp
GROUP BY cod_instit_financiera
ORDER BY n DESC
