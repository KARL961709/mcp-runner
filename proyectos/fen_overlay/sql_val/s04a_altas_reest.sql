-- s04a ALTAS celdas por r_reest (Ajuste Geo) = el array `cells` del artifact. Agrega fen_overlay_altas_202605_202607 por grado x tipo x r_reest -> n, pd, rd, s real, ibk_c. Marginal (no el cruce r_dir x r_reest, que pasa de 100 filas). <=84 filas -> entra completo en _resultados.txt. pac se deriva en el artifact (r>=1)
SELECT grado, tipo_ingreso AS tipo, coalesce(r_reest, 0) AS r,
  count(*) AS n,
  round(avg(pd), 5) AS pd,
  round(avg(CAST(rd12 AS double)), 5) AS rd,
  round(avg(COALESCE(s_total, 0.0)), 4) AS s,
  round(avg(COALESCE(ibk_centrado, 0.0)), 4) AS ibk_c
FROM disc_model_owner.fen_overlay_altas_202605_202607
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
