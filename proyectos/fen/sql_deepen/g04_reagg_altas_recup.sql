-- g04 espejo de g03 para ALTAS (tabla fen_altas_full_202605_202607, pd unico por sub_producto ya resuelto en s07). Re-agrega con el mismo A_d diferenciado por depto. Valido n/pd 1-a-1 vs las 84 celdas del artifact Altas antes de desplegar. READ-ONLY.
SELECT
  grado                                     AS g,
  concat('R', cast(r_fis AS varchar))       AS r,
  tipo_ingreso                              AS tipo,
  pac,
  count(*)                                  AS n,
  round(avg(pd), 5)                         AS pd,
  round(avg(coalesce(s_total, 0)), 4)       AS s,
  round(avg(CASE depto
              WHEN '02' THEN 0.913
              WHEN '20' THEN 0.756
              WHEN '11' THEN 0.649
              WHEN '12' THEN 0.606
              WHEN '13' THEN 0.532
              ELSE 0.500 END), 4)           AS a_d
FROM disc_model_owner.fen_altas_full_202605_202607
GROUP BY grado, concat('R', cast(r_fis AS varchar)), tipo_ingreso, pac
ORDER BY g, r, tipo, pac
