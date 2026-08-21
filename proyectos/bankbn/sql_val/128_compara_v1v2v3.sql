-- 128_compara_v1v2v3.sql | mide que tan distintas son v1 (PO clean), v2 (PO dirty routed) y v3 (ds/scr vigente) por personeria: nivel, brecha media/absoluta, correlacion y p95 de |v1-v3|. Responde si aplicar el factor (medido en v3) sobre v1/v2 cambia significativo o no. READ-ONLY
WITH v3d AS (
  SELECT p_codmes, tip_doc, key_value,
         TRY_CAST(prob_modelo_cal AS DOUBLE) AS v3,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
  WHERE p_codmes IN ('202606', '202607')
),
j AS (
  SELECT a.personeria,
         TRY_CAST(a.prob_modelo_cal_v1 AS DOUBLE) AS v1,
         TRY_CAST(a.prob_modelo_cal_v2 AS DOUBLE) AS v2,
         v.v3
  FROM disc_model_owner.b46029_po_scoring_v1v2_202607 a
  LEFT JOIN v3d v
    ON cast(v.p_codmes AS int) = a.p_codmes AND v.tip_doc = a.tip_doc AND v.key_value = a.key_value AND v.rn = 1
  WHERE a.p_codmes IN (202606, 202607) AND v.v3 IS NOT NULL
)
SELECT COALESCE(personeria, 'TOTAL') AS personeria,
       count(*) AS n,
       round(100 * avg(v1), 3) AS pd_v1,
       round(100 * avg(v2), 3) AS pd_v2,
       round(100 * avg(v3), 3) AS pd_v3,
       round(100 * avg(v1 - v3), 3) AS dif_medio_v1_v3,
       round(100 * avg(v2 - v3), 3) AS dif_medio_v2_v3,
       round(100 * avg(abs(v1 - v3)), 3) AS dif_abs_v1_v3,
       round(100 * avg(abs(v2 - v3)), 3) AS dif_abs_v2_v3,
       round(100 * approx_percentile(abs(v1 - v3), 0.95), 3) AS p95_abs_v1_v3,
       round(corr(v1, v3), 4) AS corr_v1_v3,
       round(corr(v2, v3), 4) AS corr_v2_v3
FROM j
GROUP BY GROUPING SETS ((personeria), ())
ORDER BY personeria
