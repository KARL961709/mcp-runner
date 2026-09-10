-- s06_qa: reparto de los 13M por bucket. Confirma que suman 12.93M, cuantos se recuperaron (sin_xy_dir = R directo distrital) vs los que quedan en base (sin_ubigeo), y que r_fis/pac salen coherentes por bucket. Read-only, 3 filas
SELECT
  bucket,
  count(*)                                           AS n,
  round(avg(CAST(r_fis AS double)), 3)               AS r_fis_avg,
  sum(pac)                                           AS n_pac,
  sum(CASE WHEN ubigeo_dom IS NULL THEN 1 ELSE 0 END) AS n_sin_ubigeo,
  round(avg(pd_ppfacil), 5)                          AS pd_ppfacil_avg
FROM disc_model_owner.fen_overlay_input_13m_202608
GROUP BY bucket
ORDER BY bucket
