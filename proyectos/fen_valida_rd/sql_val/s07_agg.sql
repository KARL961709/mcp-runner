-- s07_agg: celdas grado x r_fis x tipo x pac del libro de altas full (19539, XY reest + sin-XY directo distrital fusionados por su r_fis), n + PD calibrada media + s + ibk. Para re-embeber el artifact Altas. La rd por grado se aplica en el embed (rd_g del libro maduro, no el target inmaduro). Read-only, ~84 filas
SELECT
  grado,
  r_fis AS r,
  tipo_ingreso AS tipo,
  pac,
  count(*)                    AS n,
  round(avg(pd), 5)           AS pd,
  round(avg(s_total), 4)      AS s,
  round(avg(ibk_centrado), 4) AS ibk_c
FROM disc_model_owner.fen_altas_full_202605_202607
GROUP BY grado, r_fis, tipo_ingreso, pac
ORDER BY grado, r_fis, tipo_ingreso, pac
