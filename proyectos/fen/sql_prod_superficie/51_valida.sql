-- Validacion agregada de la asignacion. Todo son conteos: nada de identificadores.
SELECT 'cobertura' AS chequeo, COUNT(*) AS clientes,
       SUM(CASE WHEN e_inu IS NOT NULL THEN 1 ELSE 0 END) AS con_exposicion,
       ROUND(100.0 * SUM(CASE WHEN e_inu IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct
FROM disc_model_owner.fen_exposicion_cliente
UNION ALL
SELECT 'centrado (debe dar ~0)', COUNT(*), NULL,
       ROUND(AVG(et_inu), 6) FROM disc_model_owner.fen_exposicion_cliente
UNION ALL
SELECT 'lejania del punto mas cercano', COUNT(*),
       SUM(CASE WHEN km_al_punto_mas_cercano > 5 THEN 1 ELSE 0 END),
       ROUND(APPROX_PERCENTILE(km_al_punto_mas_cercano, 0.9), 3)
FROM disc_model_owner.fen_exposicion_cliente
