-- s07_qa: reparto del libro de altas full por bucket. Confirma que suman 19539, cuantos recuperados (sin_xy_dir = R directo distrital) vs base (sin_ubigeo). Read-only, 3 filas
SELECT
  bucket,
  count(*)                             AS n,
  round(avg(CAST(r_fis AS double)), 3) AS r_fis_avg,
  sum(pac)                             AS n_pac,
  round(avg(pd), 5)                    AS pd_avg
FROM disc_model_owner.fen_altas_full_202605_202607
GROUP BY bucket
ORDER BY bucket
