-- f12 RD por grupo R en ventana BASE (La Nina 202101-202212) vs EL NINO (202301-202412)
--     stock VC, cohorte cerrado (def12_vc maduro). El overlay de estres esta en el spread R45-R1
WITH j AS (
  SELECT CASE WHEN t.codmes BETWEEN '202101' AND '202212' THEN '1_base_lanina'
              WHEN t.codmes BETWEEN '202301' AND '202412' THEN '2_elnino'
              ELSE 'x_otro' END AS ventana,
         g.r_label,
         CAST(t.def12_vc AS double) AS d
  FROM disc_model_owner.enr_stock_vc_fem_3 t
  JOIN disc_model_owner.grado_elnino_lookup_v3 g
    ON regexp_replace(normalize(t.dep_ubi_domicilio, NFD), '\p{M}', '') = g.dep
   AND regexp_replace(normalize(t.pro_ubi_domicilio, NFD), '\p{M}', '') = g.prov
   AND regexp_replace(normalize(t.dis_ubi_domicilio, NFD), '\p{M}', '') = g.dist
  WHERE t.def12_vc IS NOT NULL
)
SELECT ventana,
       count(*) AS n,
       round(100.0 * avg(CASE WHEN r_label = 'R0' THEN d END), 3) AS rd_r0,
       round(100.0 * avg(CASE WHEN r_label = 'R1' THEN d END), 3) AS rd_r1,
       round(100.0 * avg(CASE WHEN r_label = 'R2' THEN d END), 3) AS rd_r2,
       round(100.0 * avg(CASE WHEN r_label = 'R3' THEN d END), 3) AS rd_r3,
       round(100.0 * avg(CASE WHEN r_label = 'R4' THEN d END), 3) AS rd_r4,
       round(100.0 * avg(CASE WHEN r_label = 'R5' THEN d END), 3) AS rd_r5,
       round(100.0 * (avg(CASE WHEN r_label IN ('R4','R5') THEN d END)
                    - avg(CASE WHEN r_label = 'R1' THEN d END)), 3) AS spread_r45_r1
FROM j
WHERE ventana <> 'x_otro'
GROUP BY ventana
ORDER BY ventana
