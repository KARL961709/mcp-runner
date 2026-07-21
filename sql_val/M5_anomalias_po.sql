-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M5_anomalias_po.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M5_anomalias_po.sql
--   sha256  : 976a4fc34647   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : las 3 rarezas de M4: copia 202510, dup 202503, bache 202512
-- =====================================================================================
-- =====================================================================================
-- M5_anomalias_po.sql | las tres cosas raras que devolvio M4
--
-- 1 · 202509 y 202510 tienen EXACTAMENTE el mismo conteo: 4,469,807 filas las dos.
--     En una poblacion de 4.4M que se mueve entre 10k y 40k por mes, que dos meses
--     consecutivos coincidan al ultimo digito no pasa por azar. La sospecha es que
--     la particion 202510 es una copia de 202509.
--     LA PRUEBA DECISIVA es si el pd_raw del MISMO cliente es identico en ambos meses.
--     El score se recalcula cada mes con informacion nueva: puede parecerse, pero no
--     puede ser bit a bit igual en millones de clientes. Si pct_pd_identica sale ~100,
--     202510 es una copia y NO se puede puntuar como mes propio.
--
-- 2 · 202503 es el UNICO mes donde n_filas != n_clientes: 4,368,535 vs 4,368,533.
--     Son 2 clientes duplicados. Chico, pero significa que el grano de la PO no es
--     unico y esas filas se duplican hasta la tabla final.
--
-- 3 · 202512 cae 2.6% (4,493,196 -> 4,377,469) y se recupera en 202601. Puede ser
--     estacional o una particion incompleta. Se compara contra sus vecinos.
--
-- NO devuelve key_value ni ningun identificador: solo conteos y porcentajes.
--
-- ~12 filas. READ-ONLY.
-- =====================================================================================

WITH s09 AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value, probabilidad
  FROM e_perm_aws.scr_admbankbpe_rsk WHERE p_codmes = '202509'
),
s10 AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value, probabilidad
  FROM e_perm_aws.scr_admbankbpe_rsk WHERE p_codmes = '202510'
),
cmp AS (
  SELECT a.key_value AS ka, b.key_value AS kb, a.probabilidad AS pa, b.probabilidad AS pb
  FROM s09 a
  FULL OUTER JOIN s10 b
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
)

-- ----------------------------------------------- 1. ¿202510 es copia de 202509?
SELECT '1. 202509 vs 202510' AS bloque, 'clientes en AMBOS meses' AS detalle,
       cast(count_if(ka IS NOT NULL AND kb IS NOT NULL) AS varchar) AS valor,
       '' AS criterio
FROM cmp
UNION ALL SELECT '1. 202509 vs 202510', 'solo en 202509',
       cast(count_if(kb IS NULL) AS varchar),
       'si es 0 y solo-202510 tambien, los padrones son IDENTICOS'
FROM cmp
UNION ALL SELECT '1. 202509 vs 202510', 'solo en 202510',
       cast(count_if(ka IS NULL) AS varchar), ''
FROM cmp
UNION ALL SELECT '1. 202509 vs 202510', 'pd_raw IDENTICA bit a bit',
       cast(count_if(ka IS NOT NULL AND kb IS NOT NULL AND pa = pb) AS varchar),
       cast(round(100.0 * count_if(ka IS NOT NULL AND kb IS NOT NULL AND pa = pb)
                / nullif(count_if(ka IS NOT NULL AND kb IS NOT NULL), 0), 2) AS varchar)
       || ' %  <-- ~100 = 202510 ES COPIA'
FROM cmp
UNION ALL SELECT '1. 202509 vs 202510', 'pd_raw promedio 202509 / 202510',
       cast(round(avg(pa), 8) AS varchar) || ' / ' || cast(round(avg(pb), 8) AS varchar),
       'iguales al 8vo decimal = copia'
FROM cmp

-- ----------------------------------------------- 2. los 2 duplicados de 202503
UNION ALL SELECT '2. DUPLICADOS 202503', 'claves con mas de una fila',
       cast(count(*) AS varchar), 'M4 dijo 2'
FROM (SELECT cast(tip_doc AS varchar) AS t, key_value
      FROM e_perm_aws.scr_admbankbpe_rsk WHERE p_codmes = '202503'
      GROUP BY 1,2 HAVING count(*) > 1) d
UNION ALL SELECT '2. DUPLICADOS 202503', 'filas de sobra que arrastran',
       cast(coalesce(sum(n) - count(*), 0) AS varchar),
       'se duplican hasta la tabla final'
FROM (SELECT cast(tip_doc AS varchar) AS t, key_value, count(*) AS n
      FROM e_perm_aws.scr_admbankbpe_rsk WHERE p_codmes = '202503'
      GROUP BY 1,2 HAVING count(*) > 1) d

-- 2b · ¿pasa en algun otro mes? M4 solo comparo los dos totales por mes; esto
-- confirma que 202503 es el unico. Barre toda la ventana.
UNION ALL SELECT '2b. DUP OTROS MESES', p_codmes,
       cast(count(*) - count(DISTINCT cast(tip_doc AS varchar) || '|' || key_value) AS varchar),
       'debe ser 0'
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE p_codmes BETWEEN '202401' AND '202606'
GROUP BY p_codmes
HAVING count(*) - count(DISTINCT cast(tip_doc AS varchar) || '|' || key_value) > 0

-- ----------------------------------------------- 3. el bache de 202512
UNION ALL SELECT '3. BACHE 202512', p_codmes,
       cast(count(*) AS varchar),
       'pd_raw prom ' || cast(round(avg(probabilidad), 6) AS varchar)
       || ' · nulos ' || cast(count_if(probabilidad IS NULL) AS varchar)
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE p_codmes IN ('202511','202512','202601')
GROUP BY p_codmes

ORDER BY 1, 2
