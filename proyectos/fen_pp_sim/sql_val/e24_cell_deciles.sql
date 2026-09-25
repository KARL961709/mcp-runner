-- e24_cell_deciles.sql | deciles de PD base por celda grado_base x R x depto (+ s/rec/macro promedio) para sub-buckets del simulador, que el artifact cuadre con la tabla por cliente
WITH b AS (
  SELECT
    CASE WHEN punt_esc1_base>=985 THEN 'G1' WHEN punt_esc1_base>=955 THEN 'G2' WHEN punt_esc1_base>=947 THEN 'G3' WHEN punt_esc1_base>=912 THEN 'G4' WHEN punt_esc1_base>=892 THEN 'G5' WHEN punt_esc1_base>=864 THEN 'G6' ELSE 'GR' END AS gbase,
    r_reest AS r, dep_inei AS dep, pd_esc1_base AS pd0, s_norm, rec_d, macro_shift
  FROM disc_model_owner.fen_pd_escenarios_2609
),
q AS (
  SELECT gbase, r, dep, count(*) AS n, avg(s_norm) AS s_avg, avg(rec_d) AS rec_avg, avg(macro_shift) AS macro_avg,
         approx_percentile(pd0, ARRAY[0.05,0.15,0.25,0.35,0.45,0.55,0.65,0.75,0.85,0.95]) AS pdq
  FROM b GROUP BY gbase, r, dep
)
SELECT gbase, r, dep, n, round(s_avg,4) AS s_avg, round(rec_avg,4) AS rec_avg, round(macro_avg,5) AS macro_avg,
  round(pdq[1],5) AS p05, round(pdq[2],5) AS p15, round(pdq[3],5) AS p25, round(pdq[4],5) AS p35, round(pdq[5],5) AS p45,
  round(pdq[6],5) AS p55, round(pdq[7],5) AS p65, round(pdq[8],5) AS p75, round(pdq[9],5) AS p85, round(pdq[10],5) AS p95
FROM q ORDER BY gbase, r, dep