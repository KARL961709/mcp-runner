-- e23_mig_distribucion.sql | distribucion de grado (%) por escenario. ttc y esc1 base = referencia, esc2/3/4 = estres
WITH g AS (
  SELECT
    CASE WHEN punt_ttc>=985 THEN 1 WHEN punt_ttc>=955 THEN 2 WHEN punt_ttc>=947 THEN 3 WHEN punt_ttc>=912 THEN 4 WHEN punt_ttc>=892 THEN 5 WHEN punt_ttc>=864 THEN 6 ELSE 7 END AS gt,
    CASE WHEN punt_esc1_base>=985 THEN 1 WHEN punt_esc1_base>=955 THEN 2 WHEN punt_esc1_base>=947 THEN 3 WHEN punt_esc1_base>=912 THEN 4 WHEN punt_esc1_base>=892 THEN 5 WHEN punt_esc1_base>=864 THEN 6 ELSE 7 END AS g1,
    CASE WHEN punt_esc2_fen70>=985 THEN 1 WHEN punt_esc2_fen70>=955 THEN 2 WHEN punt_esc2_fen70>=947 THEN 3 WHEN punt_esc2_fen70>=912 THEN 4 WHEN punt_esc2_fen70>=892 THEN 5 WHEN punt_esc2_fen70>=864 THEN 6 ELSE 7 END AS g2,
    CASE WHEN punt_esc3_macropes>=985 THEN 1 WHEN punt_esc3_macropes>=955 THEN 2 WHEN punt_esc3_macropes>=947 THEN 3 WHEN punt_esc3_macropes>=912 THEN 4 WHEN punt_esc3_macropes>=892 THEN 5 WHEN punt_esc3_macropes>=864 THEN 6 ELSE 7 END AS g3,
    CASE WHEN punt_esc4_macropes_fen50>=985 THEN 1 WHEN punt_esc4_macropes_fen50>=955 THEN 2 WHEN punt_esc4_macropes_fen50>=947 THEN 3 WHEN punt_esc4_macropes_fen50>=912 THEN 4 WHEN punt_esc4_macropes_fen50>=892 THEN 5 WHEN punt_esc4_macropes_fen50>=864 THEN 6 ELSE 7 END AS g4
  FROM disc_model_owner.fen_pd_escenarios_2609
)
SELECT '1_ttc' AS escenario, round(100.0*count_if(gt=1)/count(*),2) AS G1, round(100.0*count_if(gt=2)/count(*),2) AS G2, round(100.0*count_if(gt=3)/count(*),2) AS G3, round(100.0*count_if(gt=4)/count(*),2) AS G4, round(100.0*count_if(gt=5)/count(*),2) AS G5, round(100.0*count_if(gt=6)/count(*),2) AS G6, round(100.0*count_if(gt=7)/count(*),2) AS GR FROM g
UNION ALL
SELECT '2_esc1_base' AS escenario, round(100.0*count_if(g1=1)/count(*),2) AS G1, round(100.0*count_if(g1=2)/count(*),2) AS G2, round(100.0*count_if(g1=3)/count(*),2) AS G3, round(100.0*count_if(g1=4)/count(*),2) AS G4, round(100.0*count_if(g1=5)/count(*),2) AS G5, round(100.0*count_if(g1=6)/count(*),2) AS G6, round(100.0*count_if(g1=7)/count(*),2) AS GR FROM g
UNION ALL
SELECT '3_esc2_fen' AS escenario, round(100.0*count_if(g2=1)/count(*),2) AS G1, round(100.0*count_if(g2=2)/count(*),2) AS G2, round(100.0*count_if(g2=3)/count(*),2) AS G3, round(100.0*count_if(g2=4)/count(*),2) AS G4, round(100.0*count_if(g2=5)/count(*),2) AS G5, round(100.0*count_if(g2=6)/count(*),2) AS G6, round(100.0*count_if(g2=7)/count(*),2) AS GR FROM g
UNION ALL
SELECT '4_esc3_macro' AS escenario, round(100.0*count_if(g3=1)/count(*),2) AS G1, round(100.0*count_if(g3=2)/count(*),2) AS G2, round(100.0*count_if(g3=3)/count(*),2) AS G3, round(100.0*count_if(g3=4)/count(*),2) AS G4, round(100.0*count_if(g3=5)/count(*),2) AS G5, round(100.0*count_if(g3=6)/count(*),2) AS G6, round(100.0*count_if(g3=7)/count(*),2) AS GR FROM g
UNION ALL
SELECT '5_esc4_pes_fen' AS escenario, round(100.0*count_if(g4=1)/count(*),2) AS G1, round(100.0*count_if(g4=2)/count(*),2) AS G2, round(100.0*count_if(g4=3)/count(*),2) AS G3, round(100.0*count_if(g4=4)/count(*),2) AS G4, round(100.0*count_if(g4=5)/count(*),2) AS G5, round(100.0*count_if(g4=6)/count(*),2) AS G6, round(100.0*count_if(g4=7)/count(*),2) AS GR FROM g
ORDER BY escenario