-- RD por grupo R0-R5 x codmes | STOCK PP | cohorte cerrado (def12 maduro)
-- RD = MALO/(BUENO+MALO). Historia 202201+. Join por NOMBRE a la lookup.
WITH j AS (
  SELECT t.codmes, g.r_label, CAST(t.def12 AS double) d
  FROM disc_model_owner.ENR_STOCK_PP_FEM_3 t
  JOIN disc_model_owner.grado_elnino_lookup_v3 g
    ON regexp_replace(normalize(t.dep_ubi_domicilio,NFD),'\p{M}','')=g.dep
   AND regexp_replace(normalize(t.pro_ubi_domicilio,NFD),'\p{M}','')=g.prov
   AND regexp_replace(normalize(t.dis_ubi_domicilio,NFD),'\p{M}','')=g.dist
  WHERE t.def12 IS NOT NULL
)
SELECT codmes, count(*) AS n,
  round(100.0*avg(CASE WHEN r_label='R0' THEN d END),2) AS R0,
  round(100.0*avg(CASE WHEN r_label='R1' THEN d END),2) AS R1,
  round(100.0*avg(CASE WHEN r_label='R2' THEN d END),2) AS R2,
  round(100.0*avg(CASE WHEN r_label='R3' THEN d END),2) AS R3,
  round(100.0*avg(CASE WHEN r_label='R4' THEN d END),2) AS R4,
  round(100.0*avg(CASE WHEN r_label='R5' THEN d END),2) AS R5,
  round(100.0*(avg(CASE WHEN r_label IN ('R4','R5') THEN d END)
              -avg(CASE WHEN r_label='R1' THEN d END)),2) AS spread_R45_R1
FROM j GROUP BY codmes ORDER BY codmes;
