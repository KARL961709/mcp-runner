-- e23_mig_conteo.sql | migracion vs base (esc1). baja=peor grado que el base, gr=entra a GR desde no-GR, sube=mejor (solo ttc)
WITH g AS (
  SELECT
    CASE WHEN punt_ttc>=985 THEN 1 WHEN punt_ttc>=955 THEN 2 WHEN punt_ttc>=947 THEN 3 WHEN punt_ttc>=912 THEN 4 WHEN punt_ttc>=892 THEN 5 WHEN punt_ttc>=864 THEN 6 ELSE 7 END AS gt,
    CASE WHEN punt_esc1_base>=985 THEN 1 WHEN punt_esc1_base>=955 THEN 2 WHEN punt_esc1_base>=947 THEN 3 WHEN punt_esc1_base>=912 THEN 4 WHEN punt_esc1_base>=892 THEN 5 WHEN punt_esc1_base>=864 THEN 6 ELSE 7 END AS g1,
    CASE WHEN punt_esc2_fen70>=985 THEN 1 WHEN punt_esc2_fen70>=955 THEN 2 WHEN punt_esc2_fen70>=947 THEN 3 WHEN punt_esc2_fen70>=912 THEN 4 WHEN punt_esc2_fen70>=892 THEN 5 WHEN punt_esc2_fen70>=864 THEN 6 ELSE 7 END AS g2,
    CASE WHEN punt_esc3_macropes>=985 THEN 1 WHEN punt_esc3_macropes>=955 THEN 2 WHEN punt_esc3_macropes>=947 THEN 3 WHEN punt_esc3_macropes>=912 THEN 4 WHEN punt_esc3_macropes>=892 THEN 5 WHEN punt_esc3_macropes>=864 THEN 6 ELSE 7 END AS g3,
    CASE WHEN punt_esc4_macropes_fen50>=985 THEN 1 WHEN punt_esc4_macropes_fen50>=955 THEN 2 WHEN punt_esc4_macropes_fen50>=947 THEN 3 WHEN punt_esc4_macropes_fen50>=912 THEN 4 WHEN punt_esc4_macropes_fen50>=892 THEN 5 WHEN punt_esc4_macropes_fen50>=864 THEN 6 ELSE 7 END AS g4
  FROM disc_model_owner.fen_pd_escenarios_2609
)
SELECT
  count(*) AS n,
  count_if(gt<g1)                 AS ttc_mejor_que_base,
  count_if(g2>g1)                 AS baja_esc2_fen,   count_if(g2=7 AND g1<7) AS gr_esc2_fen,
  count_if(g3>g1)                 AS baja_esc3_macro, count_if(g3=7 AND g1<7) AS gr_esc3_macro,
  count_if(g4>g1)                 AS baja_esc4_pesfen,count_if(g4=7 AND g1<7) AS gr_esc4_pesfen
FROM g