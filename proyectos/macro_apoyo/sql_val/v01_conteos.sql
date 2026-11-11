-- 01 conteos de la carga (esperado: 5511 filas, 78 tickers, suma 227807874.7919, sin_maestro 0, maestro 78)
SELECT 'proy' AS tabla, p_codmes, nro_carga, COUNT(*) AS filas, COUNT(DISTINCT ticker) AS tickers,
       ROUND(SUM(valor), 4) AS suma_valor
FROM disc_model_owner.macro_apoyo_proy GROUP BY p_codmes, nro_carga
UNION ALL
SELECT 'maestro', NULL, NULL, COUNT(*), COUNT(DISTINCT ticker), NULL FROM disc_model_owner.macro_apoyo_ticker
UNION ALL
SELECT 'sin_maestro', NULL, NULL, COUNT(*), COUNT(DISTINCT p.ticker), NULL
FROM disc_model_owner.macro_apoyo_proy p LEFT JOIN disc_model_owner.macro_apoyo_ticker d ON d.ticker = p.ticker
WHERE d.ticker IS NULL
