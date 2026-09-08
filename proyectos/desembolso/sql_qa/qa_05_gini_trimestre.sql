-- qa_05_gini_trimestre.sql | Gini del score crudo pd_raw contra target_12m por TRIMESTRE de cohorte (mismo metodo Mann-Whitney con rango promedio que qa_04). Solo filas con pd_raw NO NULL y target_12m NO NULL (madura a 12m). Muestra la evolucion del poder discriminante trimestre a trimestre, mas TOTAL. READ-ONLY
WITH base AS (
  SELECT pd_raw AS s, cast(target_12m AS int) AS y,
         concat(cast(cod_mes / 100 AS varchar), 'Q', cast((cod_mes % 100 - 1) / 3 + 1 AS varchar)) AS trimestre
  FROM disc_model_owner.b46029_desemb_cal_202609
  WHERE pd_raw IS NOT NULL AND target_12m IS NOT NULL
),
dup AS (
  SELECT s, y, trimestre AS grupo FROM base
  UNION ALL SELECT s, y, 'TOTAL' AS grupo FROM base
),
ranked AS (
  SELECT grupo, y, s,
    rank() OVER (PARTITION BY grupo ORDER BY s) AS min_rank,
    count(*) OVER (PARTITION BY grupo, s) AS cnt
  FROM dup
),
ar AS (
  SELECT grupo, y, (min_rank + (cnt - 1) / 2.0) AS r FROM ranked
),
agg AS (
  SELECT grupo,
    sum(CASE WHEN y = 1 THEN r ELSE 0 END) AS r_pos,
    sum(CASE WHEN y = 1 THEN 1 ELSE 0 END) AS n_pos,
    sum(CASE WHEN y = 0 THEN 1 ELSE 0 END) AS n_neg,
    count(*) AS n
  FROM ar GROUP BY grupo
)
SELECT grupo,
  n,
  n_pos AS malos,
  round(100.0 * n_pos / n, 2) AS rd_pct,
  round((r_pos - n_pos * (n_pos + 1) / 2.0) / (n_pos * n_neg), 4) AS auc,
  round(2.0 * (r_pos - n_pos * (n_pos + 1) / 2.0) / (n_pos * n_neg) - 1.0, 4) AS gini
FROM agg
WHERE n_pos > 0 AND n_neg > 0
ORDER BY grupo
