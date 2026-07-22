-- Composición n y %n por grupo R0-R5 x codmes | STOCK TC
-- SIN cohorte cerrado: usa TODAS las filas (incluye el período más reciente).
WITH j AS (
  SELECT t.codmes, g.r_label
  FROM disc_model_owner.ENR_STOCK_TC_FEM_3 t
  JOIN disc_model_owner.grado_elnino_lookup_v3 g
    ON regexp_replace(normalize(t.dep_ubi_domicilio,NFD),'\p{M}','')=g.dep
   AND regexp_replace(normalize(t.pro_ubi_domicilio,NFD),'\p{M}','')=g.prov
   AND regexp_replace(normalize(t.dis_ubi_domicilio,NFD),'\p{M}','')=g.dist
)
SELECT codmes, count(*) AS n_total,
  round(100.0*sum(CASE WHEN r_label='R0' THEN 1 ELSE 0 END)/count(*),2) AS pct_R0,
  round(100.0*sum(CASE WHEN r_label='R1' THEN 1 ELSE 0 END)/count(*),2) AS pct_R1,
  round(100.0*sum(CASE WHEN r_label='R2' THEN 1 ELSE 0 END)/count(*),2) AS pct_R2,
  round(100.0*sum(CASE WHEN r_label='R3' THEN 1 ELSE 0 END)/count(*),2) AS pct_R3,
  round(100.0*sum(CASE WHEN r_label='R4' THEN 1 ELSE 0 END)/count(*),2) AS pct_R4,
  round(100.0*sum(CASE WHEN r_label='R5' THEN 1 ELSE 0 END)/count(*),2) AS pct_R5,
  round(100.0*sum(CASE WHEN r_label IN ('R4','R5') THEN 1 ELSE 0 END)/count(*),2) AS pct_R45
FROM j GROUP BY codmes ORDER BY codmes;
