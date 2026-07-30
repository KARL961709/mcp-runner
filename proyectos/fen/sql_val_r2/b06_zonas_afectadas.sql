-- b06 CLASIFICACION ALTERNA del banco -- nivel observado de zonas afectadas
SELECT desc_nivel,
       count(*)                            AS n_filas,
       count(DISTINCT cod_ubigeo)          AS n_ubigeo,
       count(DISTINCT desc_departamento)   AS n_dep
FROM d_perm_aws.t_mst_zonas_afectadas_tmp
GROUP BY desc_nivel
ORDER BY desc_nivel
