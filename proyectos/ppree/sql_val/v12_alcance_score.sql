-- v12_alcance_score.sql | hasta que mes hay score crudo, en las DOS tablas hermanas
-- Read-only. El scoring de stock lee ..._itc_reprocesov4 y la calibracion aprendio con
-- ..._itc_reen_reprocesov4. Comparten convencion de codmes (c6: 499,506 pares con PD
-- identica, dif 0.0), pero no tienen por que cargarse el mismo dia: por eso se miden
-- las dos y no se supone que van juntas.
-- El scoring ancla codmes_drv = codmes_score - 1 (02_score_stock_pp.sql:43), asi que el
-- ultimo mes scoreable es el maximo codmes con pd no nula, menos uno.
-- n_pd_no_nulo es la columna que manda: el CTE d filtra pd_comppp_reen_itc IS NOT NULL,
-- de modo que un mes cargado pero sin pd no produce ninguna fila scoreada.
SELECT 'stock  (lo que scorea 02)' AS tabla,
       CAST(v.codmes AS VARCHAR)                                                                 AS codmes_score,
       DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_drv,
       COUNT(1)                                                                                  AS n_filas,
       COUNT(v.pd_comppp_reen_itc)                                                               AS n_pd_no_nulo,
       COUNT(DISTINCT CAST(v.key_value AS VARCHAR))                                              AS n_llaves,
       ROUND(100.0 * AVG(v.pd_comppp_reen_itc), 4)                                               AS pd_media_pct
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
WHERE CAST(v.codmes AS VARCHAR) >= '202601'
GROUP BY CAST(v.codmes AS VARCHAR)
UNION ALL
SELECT 'reen   (con la que se calibro)' AS tabla,
       CAST(w.codmes AS VARCHAR),
       DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(w.codmes AS VARCHAR), '%Y%m')), '%Y%m'),
       COUNT(1),
       COUNT(w.pd_comppp_reen_itc),
       COUNT(DISTINCT CAST(w.key_value AS VARCHAR)),
       ROUND(100.0 * AVG(w.pd_comppp_reen_itc), 4)
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4 w
WHERE CAST(w.codmes AS VARCHAR) >= '202601'
GROUP BY CAST(w.codmes AS VARCHAR)
ORDER BY 1, 2 DESC
