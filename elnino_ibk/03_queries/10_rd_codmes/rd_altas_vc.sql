-- RD por grupo R0-R5 x codmes(cohorte de alta) | ALTAS VC (PP+TC combinado) | cohorte cerrado
-- RD = avg(DEF12_VC_) (target combinado de venta cruzada; malo si bad en TC o PP).
-- Universo: todas las altas (SOLO_TC u SOLO_PP). Madurez: DEF12_VC_ no nulo (codmes<=202503).
WITH j AS (
  SELECT t.codmes, g.r_label, CAST(t.DEF12_VC_ AS double) d
  FROM disc_model_owner.ENR_VC_FEM_3 t
  JOIN disc_model_owner.grado_elnino_lookup_v3 g
    ON regexp_replace(normalize(t.dep_ubi_domicilio,NFD),'\p{M}','')=g.dep
   AND regexp_replace(normalize(t.pro_ubi_domicilio,NFD),'\p{M}','')=g.prov
   AND regexp_replace(normalize(t.dis_ubi_domicilio,NFD),'\p{M}','')=g.dist
  WHERE t.DEF12_VC_ IS NOT NULL
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
