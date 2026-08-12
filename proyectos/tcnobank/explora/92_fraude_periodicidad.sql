-- 92_fraude_periodicidad.sql | t_mst_fraude_rsk tiene 38 particiones, asi que es periodica y no una foto: el snapshot lo produce el USO en la PO, que barre todo con RANK sin filtro temporal. Falta saber si cada particion es la foto COMPLETA del acumulado o solo las altas del mes, porque eso decide si el reanclaje va con p_codmes = T0-2 o con p_codmes <= T0-2
SELECT p_codmes,
       count(*)                                                        AS n_filas,
       count(DISTINCT key_value)                                       AS claves,
       count(DISTINCT tipo)                                            AS n_tipos,
       count(DISTINCT estado)                                          AS n_estados,
       min(codmes)                                                     AS codmes_min,
       max(codmes)                                                     AS codmes_max,
       min(substr(CAST(fecha_creacion AS VARCHAR), 1, 7))              AS crea_min,
       max(substr(CAST(fecha_creacion AS VARCHAR), 1, 7))              AS crea_max
FROM e_perm_aws.t_mst_fraude_rsk
GROUP BY p_codmes
ORDER BY p_codmes
