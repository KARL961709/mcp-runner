-- s04b PEA celdas por r_dir (Directo/nativo) = el array `cellsDir` del artifact universo. Agrega fen_overlay_input_202608 por grado x tipo x r_dir -> n, pd_facil, pd_cd, s real, ibk_c. Marginal. SIN rd (universo inmaduro). <=84 filas -> _resultados.txt completo. pac se deriva en el artifact (r>=1)
SELECT grado, tipo_ingreso AS tipo, coalesce(r_dir, 0) AS r,
  count(*) AS n,
  round(avg(pd_ppfacil), 5) AS pd_facil,
  round(avg(pd_ppcd), 5) AS pd_cd,
  round(avg(COALESCE(s_total, 0.0)), 4) AS s,
  round(avg(COALESCE(ibk_centrado, 0.0)), 4) AS ibk_c
FROM disc_model_owner.fen_overlay_input_202608
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
