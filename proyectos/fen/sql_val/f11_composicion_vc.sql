-- f11 EXPOSICION de la cartera por grupo R en los ultimos meses (stock VC, sin cohorte cerrado)
--     R4+R5 es el numero que el deck reporta como 22.4% / 27.1%: aca sale con su base explicita
WITH j AS (
  SELECT t.codmes, coalesce(g.r_label, 'SIN_MATCH') AS r_label
  FROM disc_model_owner.enr_stock_vc_fem_3 t
  LEFT JOIN disc_model_owner.grado_elnino_lookup_v3 g
         ON regexp_replace(normalize(t.dep_ubi_domicilio, NFD), '\p{M}', '') = g.dep
        AND regexp_replace(normalize(t.pro_ubi_domicilio, NFD), '\p{M}', '') = g.prov
        AND regexp_replace(normalize(t.dis_ubi_domicilio, NFD), '\p{M}', '') = g.dist
  WHERE t.codmes >= '202501'
)
SELECT codmes,
       count(*) AS n_total,
       round(100.0 * sum(CASE WHEN r_label = 'R0' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r0,
       round(100.0 * sum(CASE WHEN r_label = 'R1' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r1,
       round(100.0 * sum(CASE WHEN r_label = 'R2' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r2,
       round(100.0 * sum(CASE WHEN r_label = 'R3' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r3,
       round(100.0 * sum(CASE WHEN r_label = 'R4' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r4,
       round(100.0 * sum(CASE WHEN r_label = 'R5' THEN 1 ELSE 0 END) / count(*), 2) AS pct_r5,
       round(100.0 * sum(CASE WHEN r_label IN ('R4','R5') THEN 1 ELSE 0 END) / count(*), 2) AS pct_r45,
       round(100.0 * sum(CASE WHEN r_label = 'SIN_MATCH' THEN 1 ELSE 0 END) / count(*), 2) AS pct_sin_match
FROM j
GROUP BY codmes
ORDER BY codmes
