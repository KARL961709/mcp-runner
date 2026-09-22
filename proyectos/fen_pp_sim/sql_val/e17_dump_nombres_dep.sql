-- e17_dump_nombres_dep.sql | por que 0 match de nombre a nivel departamento. Volcado de los nombres de depto (normalizados
-- NFD+upper) de los DOS lados: grado_elnino_ubigeo_v3 (lado grado) y t_mst_reniec_rsk (lado RENIEC, domicilio declarado).
-- Si A sale '(vacio)' -> el grado no tiene nombres (solo cod_ubigeo) y hay que cruzar por codigo. Si ambos traen nombres
-- pero distintos (p.ej. 'LIMA' vs 'LIMA / LIMA' o codigos) -> se ve el formato exacto a homologar.
-- Read-only. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e17_dump_nombres_dep
SELECT 'A_grado_dep' AS bloque,
       COALESCE(NULLIF(upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')), ''), '(vacio)') AS nombre,
       CAST(COUNT(*) AS varchar) AS n
FROM disc_model_owner.grado_elnino_ubigeo_v3
GROUP BY 1, 2
UNION ALL
SELECT 'B_reniec_dep',
       COALESCE(NULLIF(upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')), ''), '(vacio)'),
       CAST(COUNT(*) AS varchar)
FROM e_perm_aws.t_mst_reniec_rsk
WHERE tip_doc = '1'
GROUP BY 1, 2
ORDER BY bloque, CAST(n AS bigint) DESC
