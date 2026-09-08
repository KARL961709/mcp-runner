-- qa_04_gini.sql | Gini del score crudo pd_raw contra target_12m sobre b46029_desemb_cal_202609, solo filas con pd_raw NO NULL y target_12m NO NULL (cohorte madura a 12m). AUC por Mann-Whitney con rango promedio (maneja empates): AUC = (sum_rangos_malos - n_pos*(n_pos+1)/2) / (n_pos*n_neg), Gini = 2*AUC - 1. Reporta TOTAL, por anio y por personeria (tip_doc 2 = PJJ). READ-ONLY
WITH base AS (
  SELECT pd_raw AS s, cast(target_12m AS int) AS y,
         cast(cod_mes / 100 AS int) AS anio,
         CASE WHEN cod_tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END AS per
  FROM disc_model_owner.b46029_desemb_cal_202609
  WHERE pd_raw IS NOT NULL AND target_12m IS NOT NULL
),
dup AS (
  SELECT s, y, 'TOTAL' AS grupo FROM base
  UNION ALL SELECT s, y, concat('anio ', cast(anio AS varchar)) FROM base
  UNION ALL SELECT s, y, concat('per ', per) FROM base
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
