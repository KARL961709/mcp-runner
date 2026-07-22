-- RD por grupo R0-R5 x codmes(cohorte de alta) | ALTAS PP | cohorte cerrado
-- RD = MALO/(BUENO+MALO) usando el flag tipo_cliente_PP='MALO'. Madurez: DEF12_PP no nulo.
WITH j AS (
  SELECT t.codmes, g.r_label,
    CASE WHEN t.tipo_cliente_PP='MALO' THEN 1.0 ELSE 0.0 END AS malo
  FROM disc_model_owner.ENR_VC_FEM_3 t
  JOIN disc_model_owner.grado_elnino_lookup_v3 g
    ON regexp_replace(normalize(t.dep_ubi_domicilio,NFD),'\p{M}','')=g.dep
   AND regexp_replace(normalize(t.pro_ubi_domicilio,NFD),'\p{M}','')=g.prov
   AND regexp_replace(normalize(t.dis_ubi_domicilio,NFD),'\p{M}','')=g.dist
  WHERE t.tipo_producto='SOLO_PP'
    AND t.tipo_cliente_PP IN ('BUENO','MALO')
    AND t.DEF12_PP IS NOT NULL
)
SELECT codmes, count(*) AS n,
  round(100.0*avg(CASE WHEN r_label='R0' THEN malo END),2) AS R0,
  round(100.0*avg(CASE WHEN r_label='R1' THEN malo END),2) AS R1,
  round(100.0*avg(CASE WHEN r_label='R2' THEN malo END),2) AS R2,
  round(100.0*avg(CASE WHEN r_label='R3' THEN malo END),2) AS R3,
  round(100.0*avg(CASE WHEN r_label='R4' THEN malo END),2) AS R4,
  round(100.0*avg(CASE WHEN r_label='R5' THEN malo END),2) AS R5,
  round(100.0*(avg(CASE WHEN r_label IN ('R4','R5') THEN malo END)
              -avg(CASE WHEN r_label='R1' THEN malo END)),2) AS spread_R45_R1
FROM j GROUP BY codmes ORDER BY codmes;
