-- 74_gdp_rcc_ppe_contenido.sql | la tabla tiene una sola particion (202606) pero la PO la lee sin filtro de p_codmes y usa la columna codmes. Si dentro de esa unica particion hay historia en codmes, el swap inferido si opera hacia atras. Si no, ese filtro no cubre lo que declara
SELECT substr(codmes, 1, 4)                                         AS anio,
       count(*)                                                     AS n_filas,
       count(DISTINCT codmes)                                       AS meses,
       min(codmes)                                                  AS codmes_min,
       max(codmes)                                                  AS codmes_max,
       sum(CASE WHEN subproducto = 'SWAP' THEN 1 ELSE 0 END)        AS n_swap,
       count(DISTINCT subproducto)                                  AS n_subproductos
FROM d_perm_aws.t_gdp_rcc_ppe
GROUP BY substr(codmes, 1, 4)
ORDER BY anio
