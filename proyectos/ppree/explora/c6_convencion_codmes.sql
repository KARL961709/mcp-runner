-- c6 | La tabla a puntuar NO es la que midio H33. Comparar la convencion de
--      codmes entre ambas antes de heredarle el rezago -1.
--      Si sobre las llaves comunes la PD coincide en el MISMO codmes, comparten
--      convencion. Si coincide corrida un mes, el rezago que aplico esta mal.
WITH a AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS k,
         CAST(cod_tip_doc AS VARCHAR) AS td, AVG(pd_comppp_reen_itc) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202601' AND '202604'
    AND pd_comppp_reen_itc IS NOT NULL
  GROUP BY 1, 2, 3
),
b AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS k,
         CAST(cod_tip_doc AS VARCHAR) AS td, AVG(pd_comppp_reen_itc) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202512' AND '202605'
    AND pd_comppp_reen_itc IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT desfase,
       COUNT(*)                                                        AS n_pares,
       SUM(CASE WHEN abs(pd_a - pd_b) < 1e-12 THEN 1 ELSE 0 END)       AS n_pd_identica,
       ROUND(100.0 * AVG(CASE WHEN abs(pd_a - pd_b) < 1e-12 THEN 1.0 ELSE 0.0 END), 2) AS pct_identica,
       ROUND(MAX(abs(pd_a - pd_b)), 10)                                AS max_dif
FROM (
  SELECT 'mismo mes' AS desfase, a.pd AS pd_a, b.pd AS pd_b
  FROM a JOIN b ON b.k = a.k AND b.td = a.td AND b.codmes = a.codmes
  UNION ALL
  SELECT 'b un mes antes', a.pd, b.pd
  FROM a JOIN b ON b.k = a.k AND b.td = a.td
             AND b.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(a.codmes, '%Y%m')), '%Y%m')
  UNION ALL
  SELECT 'b un mes despues', a.pd, b.pd
  FROM a JOIN b ON b.k = a.k AND b.td = a.td
             AND b.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(a.codmes, '%Y%m')), '%Y%m')
) t
GROUP BY desfase
ORDER BY 4 DESC
