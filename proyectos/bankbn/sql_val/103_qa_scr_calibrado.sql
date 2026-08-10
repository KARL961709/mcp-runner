-- 103_qa_scr_calibrado.sql | QA de la tabla reescrita: conserva scr_admbankbpe_rsk completa y agrega 3 columnas. Los chequeos 10 al 13 verifican que las columnas originales viajaron intactas, comparando agregados contra la fuente
WITH n AS (
    SELECT count(1)                                                             AS filas,
           count(DISTINCT p_codmes)                                             AS periodos,
           min(p_codmes)                                                        AS pm_min,
           max(p_codmes)                                                        AS pm_max,
           sum(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)             AS sin_pd,
           sum(CASE WHEN puntuacion_modelo IS NULL THEN 1 ELSE 0 END)           AS sin_punt,
           sum(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1 THEN 1 ELSE 0 END) AS pit_fuera,
           sum(CASE WHEN puntuacion_modelo < 0 OR puntuacion_modelo > 1000 THEN 1 ELSE 0 END) AS punt_fuera,
           sum(CASE WHEN puntuacion_modelo <> CAST(round((1.0 - prob_modelo_cal) * 1000) AS INTEGER)
                    THEN 1 ELSE 0 END)                                          AS punt_mal,
           round(sum(TRY_CAST(probabilidad AS DOUBLE)), 4)                      AS sum_prob,
           sum(CAST(puntuacion AS BIGINT))                                      AS sum_punt_orig,
           count(DISTINCT modelo)                                               AS n_modelos,
           count(DISTINCT segmento)                                             AS n_segmentos,
           sum(CASE WHEN tip_doc = '2' THEN 1 ELSE 0 END)                       AS n_pjj,
           avg(prob_modelo_cal)                                                 AS med_cal
    FROM disc_model_owner.scr_admbankbpe_calibrado_202607
),
f AS (
    SELECT count(1)                                                             AS filas,
           round(sum(TRY_CAST(probabilidad AS DOUBLE)), 4)                      AS sum_prob,
           sum(CAST(puntuacion AS BIGINT))                                      AS sum_punt_orig,
           count(DISTINCT modelo)                                               AS n_modelos,
           count(DISTINCT segmento)                                             AS n_segmentos
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202206' AND '202607'
      AND probabilidad IS NOT NULL
),
d AS (
    SELECT count(1) AS repetidas
    FROM (SELECT tip_doc, key_value, p_codmes, count(1) AS c
          FROM disc_model_owner.scr_admbankbpe_calibrado_202607
          GROUP BY tip_doc, key_value, p_codmes
          HAVING count(1) > 1) z
)
SELECT orden, chequeo, round(valor, 6) AS valor, referencia,
       CASE WHEN ok = 1 THEN 'OK' ELSE '** REVISAR **' END AS veredicto
FROM (
    SELECT 1 AS orden, 'filas = filas de la fuente' AS chequeo,
           CAST(n.filas AS DOUBLE) AS valor, CAST(f.filas AS VARCHAR) AS referencia,
           CASE WHEN n.filas = f.filas THEN 1 ELSE 0 END AS ok FROM n, f
    UNION ALL SELECT 2, 'periodos distintos', CAST(n.periodos AS DOUBLE), '50 (202206-202607)',
           CASE WHEN n.periodos = 50 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 3, 'primer p_codmes', CAST(CAST(n.pm_min AS INT) AS DOUBLE), '202206',
           CASE WHEN n.pm_min = '202206' THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 4, 'ultimo p_codmes', CAST(CAST(n.pm_max AS INT) AS DOUBLE), '202607',
           CASE WHEN n.pm_max = '202607' THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 5, 'sin prob_modelo_cal', CAST(n.sin_pd AS DOUBLE), '0',
           CASE WHEN n.sin_pd = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 6, 'sin puntuacion_modelo', CAST(n.sin_punt AS DOUBLE), '0',
           CASE WHEN n.sin_punt = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 7, 'prob_modelo_cal fuera de (0,1)', CAST(n.pit_fuera AS DOUBLE), '0',
           CASE WHEN n.pit_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 8, 'puntuacion_modelo fuera de [0,1000]', CAST(n.punt_fuera AS DOUBLE), '0',
           CASE WHEN n.punt_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 9, 'puntuacion <> round((1-pd)*1000)', CAST(n.punt_mal AS DOUBLE), '0',
           CASE WHEN n.punt_mal = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 10, 'suma de probabilidad = fuente', n.sum_prob, CAST(f.sum_prob AS VARCHAR),
           CASE WHEN abs(n.sum_prob - f.sum_prob) < 0.01 THEN 1 ELSE 0 END FROM n, f
    UNION ALL SELECT 11, 'suma de puntuacion original = fuente', CAST(n.sum_punt_orig AS DOUBLE),
           CAST(f.sum_punt_orig AS VARCHAR),
           CASE WHEN n.sum_punt_orig = f.sum_punt_orig THEN 1 ELSE 0 END FROM n, f
    UNION ALL SELECT 12, 'modelos distintos = fuente', CAST(n.n_modelos AS DOUBLE), CAST(f.n_modelos AS VARCHAR),
           CASE WHEN n.n_modelos = f.n_modelos THEN 1 ELSE 0 END FROM n, f
    UNION ALL SELECT 13, 'segmentos distintos = fuente', CAST(n.n_segmentos AS DOUBLE), CAST(f.n_segmentos AS VARCHAR),
           CASE WHEN n.n_segmentos = f.n_segmentos THEN 1 ELSE 0 END FROM n, f
    UNION ALL SELECT 14, 'claves repetidas (tip_doc, key_value, p_codmes)', CAST(d.repetidas AS DOUBLE),
           'informativo: si es 0, el grano es unico', 1 FROM d
    UNION ALL SELECT 15, 'PJJ sobre el total %', 100.0 * n.n_pjj / n.filas, 'informativo', 1 FROM n
    UNION ALL SELECT 16, 'prob_modelo_cal media %', 100.0 * n.med_cal, 'informativo', 1 FROM n
) q
ORDER BY orden
