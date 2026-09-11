-- g03 re-agrega celdas PEA con A_d de recuperacion DIFERENCIADO por depto (forma lineal A_d=1-0.50*min(r,1), IBK+ Yaku signo-corregido). Grano grado x r x tipo x pac (identico a las 84 celdas del artifact). Emite n, pd, s y a_d ponderado -> valido n/pd 1-a-1 vs celdas embebidas antes de desplegar a_d (no cambia la base). depto en codigo INEI 2 digitos. READ-ONLY.
SELECT
  grado                                     AS g,
  concat('R', cast(r_fis AS varchar))       AS r,
  tipo_ingreso                              AS tipo,
  pac,
  count(*)                                  AS n,
  round(avg(pd_ppfacil), 5)                 AS pd,
  round(avg(coalesce(s_total, 0)), 4)       AS s,
  round(avg(CASE depto
              WHEN '02' THEN 0.913
              WHEN '20' THEN 0.756
              WHEN '11' THEN 0.649
              WHEN '12' THEN 0.606
              WHEN '13' THEN 0.532
              ELSE 0.500 END), 4)           AS a_d
FROM disc_model_owner.fen_overlay_input_13m_202608
GROUP BY grado, concat('R', cast(r_fis AS varchar)), tipo_ingreso, pac
ORDER BY g, r, tipo, pac
