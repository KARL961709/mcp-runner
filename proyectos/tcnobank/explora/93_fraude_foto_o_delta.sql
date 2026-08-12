-- 93_fraude_foto_o_delta.sql | test que separa foto completa de delta mensual. Si la suma de claves distintas POR particion supera con mucho a las claves distintas de toda la tabla, cada particion repite el acumulado y es una foto. Si son parecidas, cada clave aparece una sola vez y son altas del mes. Ademas reparte estado y tipo, porque un fraude revertido no deberia excluir
SELECT '1. claves distintas en toda la tabla'         AS medida, CAST(count(DISTINCT key_value) AS VARCHAR) AS valor
FROM e_perm_aws.t_mst_fraude_rsk
UNION ALL
SELECT '2. suma de claves distintas por particion', CAST(sum(c) AS VARCHAR)
FROM (SELECT p_codmes, count(DISTINCT key_value) AS c FROM e_perm_aws.t_mst_fraude_rsk GROUP BY p_codmes) x
UNION ALL
SELECT '3. filas totales', CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_fraude_rsk
UNION ALL
SELECT '4. estado = ' || coalesce(estado, 'NULL'), CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_fraude_rsk
GROUP BY estado
UNION ALL
SELECT '5. tipo = ' || coalesce(tipo, 'NULL'), CAST(count(*) AS VARCHAR)
FROM e_perm_aws.t_mst_fraude_rsk
GROUP BY tipo
ORDER BY medida
LIMIT 60
