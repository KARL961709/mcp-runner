-- s04 fen_overlay_agg: AGREGADO de la tabla consolidada s03 para EMBEBER en el artifact universo. Celdas grado x R_reest x tipo x pac x depto, con n, PD media, s media REAL (no proxy) e IBK+ centrado por depto. Con esto el artifact se mueve con DATOS REALES: s por celda + IBK+ por depto (recuperacion). Read-only, pegable/embebible. Lee s03
SELECT
  grado, r_reest AS r, tipo_ingreso AS tipo, pac, depto,
  count(*)                     AS n,
  round(avg(pd_ppfacil), 5)    AS pd,
  round(avg(s_total), 4)       AS s,
  round(avg(ibk_centrado), 4)  AS ibk_c
FROM disc_model_owner.fen_overlay_input_202608
GROUP BY grado, r_reest, tipo_ingreso, pac, depto
ORDER BY grado, r_reest, tipo_ingreso, pac, depto
