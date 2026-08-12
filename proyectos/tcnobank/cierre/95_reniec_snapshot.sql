-- 95_reniec_snapshot.sql | el test que R5 exige para declarar snapshot y que no habia corrido: si filas = claves distintas, hay una fila por persona y es foto. Ademas mira fec_dato y flg_inhabilitado, dos columnas que dan ancla temporal y que descarte al no ver p_codmes
SELECT 'A. filas totales'                     AS medida, CAST(count(*) AS VARCHAR)                       AS valor
FROM e_perm_aws.t_mst_reniec_rsk
UNION ALL
SELECT 'B. key_value distintos',              CAST(count(DISTINCT key_value) AS VARCHAR)
FROM e_perm_aws.t_mst_reniec_rsk
UNION ALL
SELECT 'C. tip_doc + key_value distintos',    CAST(count(DISTINCT tip_doc || '|' || key_value) AS VARCHAR)
FROM e_perm_aws.t_mst_reniec_rsk
UNION ALL
SELECT 'D. fec_dato anio ' || coalesce(substr(CAST(fec_dato AS VARCHAR), 1, 4), 'NULL'), CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_reniec_rsk
GROUP BY substr(CAST(fec_dato AS VARCHAR), 1, 4)
UNION ALL
SELECT 'E. fec_registro anio ' || coalesce(substr(CAST(fec_registro AS VARCHAR), 1, 4), 'NULL'), CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_reniec_rsk
GROUP BY substr(CAST(fec_registro AS VARCHAR), 1, 4)
UNION ALL
SELECT 'F. flg_inhabilitado = ' || coalesce(CAST(flg_inhabilitado AS VARCHAR), 'NULL'), CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_reniec_rsk
GROUP BY flg_inhabilitado
ORDER BY medida
LIMIT 80
