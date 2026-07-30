-- f10 COBERTURA del join oficial por NOMBRE sobre la cartera (claim 99.15% en TC)
--     n_join > n_base delata fan-out de la lookup (cruzar con f05)
SELECT 'stock_tc' AS base,
       count(*)                                                        AS n_join,
       round(100.0 * avg(CASE WHEN g.cod_ubigeo IS NOT NULL THEN 1 ELSE 0 END), 2) AS pct_con_grado,
       round(100.0 * avg(CASE WHEN t.dep_ubi_domicilio IS NULL THEN 1 ELSE 0 END), 2) AS pct_sin_reniec
FROM disc_model_owner.enr_stock_tc_fem_3 t
LEFT JOIN disc_model_owner.grado_elnino_lookup_v3 g
       ON regexp_replace(normalize(t.dep_ubi_domicilio, NFD), '\p{M}', '') = g.dep
      AND regexp_replace(normalize(t.pro_ubi_domicilio, NFD), '\p{M}', '') = g.prov
      AND regexp_replace(normalize(t.dis_ubi_domicilio, NFD), '\p{M}', '') = g.dist
UNION ALL
SELECT 'stock_vc',
       count(*),
       round(100.0 * avg(CASE WHEN g.cod_ubigeo IS NOT NULL THEN 1 ELSE 0 END), 2),
       round(100.0 * avg(CASE WHEN t.dep_ubi_domicilio IS NULL THEN 1 ELSE 0 END), 2)
FROM disc_model_owner.enr_stock_vc_fem_3 t
LEFT JOIN disc_model_owner.grado_elnino_lookup_v3 g
       ON regexp_replace(normalize(t.dep_ubi_domicilio, NFD), '\p{M}', '') = g.dep
      AND regexp_replace(normalize(t.pro_ubi_domicilio, NFD), '\p{M}', '') = g.prov
      AND regexp_replace(normalize(t.dis_ubi_domicilio, NFD), '\p{M}', '') = g.dist
