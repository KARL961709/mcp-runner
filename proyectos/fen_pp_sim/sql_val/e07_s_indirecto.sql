-- e07_s_indirecto.sql | confirma el score indirecto s (fen_s_indirecto): existe, cobertura y reparto por nivel S0..S4
SELECT 'A_total' AS bloque, CAST(COUNT(*) AS varchar) AS a, CAST(COUNT(DISTINCT ubigeo) AS varchar) AS b
FROM disc_model_owner.fen_s_indirecto
UNION ALL
SELECT 'B_por_nivel', nivel, CAST(COUNT(*) AS varchar)
FROM disc_model_owner.fen_s_indirecto
GROUP BY nivel
ORDER BY bloque, a
