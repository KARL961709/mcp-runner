-- e24_cell_deciles.sql | forma intra-grado de la PD base: deciles + min/max de pd_esc1_base por grado (7 filas) para reconstruir sub-buckets del simulador y cuadrarlo con la tabla por cliente
WITH b AS (
  SELECT
    CASE WHEN punt_esc1_base>=985 THEN 'G1' WHEN punt_esc1_base>=955 THEN 'G2' WHEN punt_esc1_base>=947 THEN 'G3' WHEN punt_esc1_base>=912 THEN 'G4' WHEN punt_esc1_base>=892 THEN 'G5' WHEN punt_esc1_base>=864 THEN 'G6' ELSE 'GR' END AS gbase,
    pd_esc1_base AS pd0
  FROM disc_model_owner.fen_pd_escenarios_2609
),
q AS (
  SELECT gbase, count(*) AS n, min(pd0) AS pmin, max(pd0) AS pmax,
         approx_percentile(pd0, ARRAY[0.05,0.15,0.25,0.35,0.45,0.55,0.65,0.75,0.85,0.95]) AS pdq
  FROM b GROUP BY gbase
)
SELECT gbase, n, round(pmin,6) AS pmin, round(pmax,6) AS pmax,
  round(pdq[1],6) AS p05, round(pdq[2],6) AS p15, round(pdq[3],6) AS p25, round(pdq[4],6) AS p35, round(pdq[5],6) AS p45,
  round(pdq[6],6) AS p55, round(pdq[7],6) AS p65, round(pdq[8],6) AS p75, round(pdq[9],6) AS p85, round(pdq[10],6) AS p95
FROM q ORDER BY gbase