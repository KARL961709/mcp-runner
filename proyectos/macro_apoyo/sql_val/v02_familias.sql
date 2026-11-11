-- 02 tickers y filas por familia (esperado tickers: DEMANDA 21, ESCENARIO 3, INFLACION 3, INGRESO 6, LABORAL 15, PBI 6, PBISECTOR 24)
SELECT d.familia, COUNT(DISTINCT p.ticker) AS tickers, COUNT(*) AS filas
FROM disc_model_owner.macro_apoyo_proy p JOIN disc_model_owner.macro_apoyo_ticker d ON d.ticker = p.ticker
GROUP BY d.familia ORDER BY d.familia
