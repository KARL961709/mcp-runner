-- s04a agg celdas ALTAS para el artifact: agrega fen_overlay_altas_202605_202607 por grado x tipo x r_dir x r_reest -> n, pd media, rd media, s media, ibk_c medio. Trae AMBOS R (dir y reest) del MISMO dato -> el toggle deriva las dos vistas; s_total real (no proxy) e ibk_centrado (ventana altas). pac se deriva en el artifact (r>=1). Agregado chico (<=~500 filas) -> vuelve por _resultados.txt
SELECT
  grado, tipo_ingreso AS tipo, r_dir, r_reest,
  count(*) AS n,
  round(avg(pd), 5)                        AS pd,
  round(avg(CAST(rd12 AS double)), 5)      AS rd,
  round(avg(COALESCE(s_total, 0.0)), 4)    AS s,
  round(avg(COALESCE(ibk_centrado, 0.0)), 4) AS ibk_c
FROM disc_model_owner.fen_overlay_altas_202605_202607
GROUP BY 1, 2, 3, 4
