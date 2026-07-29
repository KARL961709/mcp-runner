-- x2  cobertura CONTANDO FILAS por mes, no por particiones declaradas
-- Confirma hasta que codmes llega realmente la tabla y si hay meses vacios
SELECT CAST(codmes AS VARCHAR) AS codmes,
       COUNT(*)                                    AS n_filas,
       COUNT(DISTINCT key_value)                   AS n_llaves,
       COUNT(*) - COUNT(DISTINCT key_value)        AS exceso_por_duplicado
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1 DESC
LIMIT 30
