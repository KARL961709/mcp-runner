-- s04b agg celdas PEA/Universo para el artifact: agrega fen_overlay_input_202608 por grado x tipo x r_dir x r_reest -> n, pd media, s media, ibk_c medio. Igual que s04a pero universo 202608, SIN rd (inmaduro). IBK+ = ibk_c_pea (mes 202608). Agregado chico -> _resultados.txt
SELECT
  grado, tipo_ingreso AS tipo, r_dir, r_reest,
  count(*) AS n,
  round(avg(pd_ppfacil), 5)                AS pd_facil,
  round(avg(pd_ppcd), 5)                   AS pd_cd,
  round(avg(COALESCE(s_total, 0.0)), 4)    AS s,
  round(avg(COALESCE(ibk_centrado, 0.0)), 4) AS ibk_c
FROM disc_model_owner.fen_overlay_input_202608
GROUP BY 1, 2, 3, 4
