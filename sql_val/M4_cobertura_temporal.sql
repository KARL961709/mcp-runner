-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M4_cobertura_temporal.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M4_cobertura_temporal.sql
--   sha256  : b7fb09011bba   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : particiones OK; destapo 202509=202510 y 2 dup en 202503
-- =====================================================================================
-- =====================================================================================
-- M4_cobertura_temporal.sql | ¿estan TODOS los meses, y completos?
--
-- EL HUECO QUE TAPA
--   M1 muestrea 3 meses y M2 uno solo. Ninguna de las dos ve el eje temporal, y ahi
--   viven fallas que no avisan:
--     * una particion faltante en scr_admbankbpe_rsk = un mes que el ladder saltea
--       sin error. Sale una tabla mas chica y parece cambio de poblacion.
--     * un codmes faltante en el RCC = flg_novig_12m_m2 se calcula sobre MENOS meses
--       de los 12 que dice su nombre, y da 0 donde deberia dar 1. Silencioso y grave:
--       manda a CLEAN gente que no lo es.
--
--   Los bloques 1 y 2 usan "$partitions": leen el catalogo, NO el dato. Son gratis.
--
-- VENTANAS
--   PO   p_codmes 202401..202607  = 31 meses
--   RCC  p_codmes 202212..202606  = 43 meses  (202401 - 14 = 202211, mas margen)
--
-- COMO SE LEE
--   Bloque 1-2: 'n_particiones' debe igualar a los meses esperados. Si no, faltan.
--   Bloque 3:   filas por mes de la PO. Una caida brusca = particion incompleta.
--   Bloque 4:   la relacion p_codmes -> codmes del RCC. M1 devolvio codmes 202604..202605
--               para p_codmes 202604..202606, que NO cuadra con un desfase fijo de 1.
--               Hay que ver el mapa explicito antes de confiar en el m-2.
--   Bloque 5:   tipo_credito no numerico. El ladder hace cast(tipo_credito as int) en
--               10 lugares: UN solo valor no numerico tumba el CTAS entero.
--   Bloque 6:   meses de la base congelada de calibracion.
--
-- ~60 filas. READ-ONLY.
-- =====================================================================================

-- ------------------------------------------------------- 1. particiones de la PO
SELECT '1. PARTICIONES PO' AS bloque,
       'presentes en 202401..202607' AS detalle,
       cast(count(*) AS varchar)     AS valor,
       'esperadas 31'                AS criterio
FROM "e_perm_aws"."scr_admbankbpe_rsk$partitions"
WHERE p_codmes BETWEEN '202401' AND '202607'

UNION ALL
SELECT '1. PARTICIONES PO', 'rango real', min(p_codmes) || ' .. ' || max(p_codmes), ''
FROM "e_perm_aws"."scr_admbankbpe_rsk$partitions"
WHERE p_codmes BETWEEN '202401' AND '202607'

-- ------------------------------------------------------- 2. particiones del RCC
UNION ALL
SELECT '2. PARTICIONES RCC', 'presentes en 202212..202606',
       cast(count(*) AS varchar), 'esperadas 43'
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
WHERE p_codmes BETWEEN '202212' AND '202606'

UNION ALL
SELECT '2. PARTICIONES RCC', 'rango real', min(p_codmes) || ' .. ' || max(p_codmes), ''
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
WHERE p_codmes BETWEEN '202212' AND '202606'

-- 2b · las que FALTAN, una por fila. Se genera el calendario esperado y se le resta
-- lo que existe. Si no aparece ninguna fila de este bloque, no falta ningun mes.
UNION ALL
SELECT '2b. RCC FALTANTES', 'mes ausente en el catalogo', mes, '*** REVISAR ***'
FROM (
  SELECT date_format(date_add('month', s.i, date_parse('202212','%Y%m')), '%Y%m') AS mes
  FROM UNNEST(sequence(0, 42)) AS s(i)
) cal
WHERE cal.mes NOT IN (
  SELECT p_codmes FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
)

-- 2c · idem para la PO
UNION ALL
SELECT '2c. PO FALTANTES', 'mes ausente en el catalogo', mes, '*** REVISAR ***'
FROM (
  SELECT date_format(date_add('month', s.i, date_parse('202401','%Y%m')), '%Y%m') AS mes
  FROM UNNEST(sequence(0, 30)) AS s(i)
) cal
WHERE cal.mes NOT IN (
  SELECT p_codmes FROM "e_perm_aws"."scr_admbankbpe_rsk$partitions"
)

-- ------------------------------------------------------- 3. volumen mes a mes de la PO
UNION ALL
SELECT '3. VOLUMEN PO', p_codmes,
       cast(count(*) AS varchar),
       'clientes distintos ' || cast(count(DISTINCT cast(tip_doc AS varchar)
                                        || '|' || key_value) AS varchar)
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE p_codmes BETWEEN '202401' AND '202607'
GROUP BY p_codmes

-- ------------------------------------------------------- 4. mapa p_codmes -> codmes del RCC
-- Solo 6 meses: alcanza para fijar la regla y no cuesta como leer los 43.
UNION ALL
SELECT '4. MAPA RCC', 'p_codmes ' || p_codmes,
       'codmes ' || min(codmes) || '..' || max(codmes),
       cast(count(DISTINCT codmes) AS varchar) || ' codmes distintos'
       || CASE WHEN count(DISTINCT codmes) > 1
               THEN '  <-- la particion NO es 1 codmes' ELSE '' END
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202601' AND '202606'
GROUP BY p_codmes

-- ------------------------------------------------------- 5. tipo_credito castea?
UNION ALL
SELECT '5. TIPO_CREDITO', 'valores NO numericos',
       cast(count(*) AS varchar),
       'DEBE ser 0 — el ladder hace cast(tipo_credito as int) en 10 lugares'
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202604' AND '202606'
  AND NOT regexp_like(trim(coalesce(tipo_credito, '')), '^[0-9]+$')

UNION ALL
SELECT '5. TIPO_CREDITO', 'valores distintos vistos',
       cast(count(DISTINCT tipo_credito) AS varchar),
       array_join(array_agg(DISTINCT tipo_credito ORDER BY tipo_credito), ' ')
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202604' AND '202606'

-- ------------------------------------------------------- 6. la base congelada
UNION ALL
SELECT '6. CALIB_SRC', 'meses con datos',
       cast(count(DISTINCT codmes) AS varchar),
       'rango ' || cast(min(cast(codmes AS int)) AS varchar)
       || '..' || cast(max(cast(codmes AS int)) AS varchar)
FROM disc_model_owner.bnbpe_ibk_calib_src

UNION ALL
SELECT '6. CALIB_SRC', 'meses en la ventana de calibracion 202207..202505',
       cast(count(DISTINCT codmes) AS varchar),
       'esperados 35'
FROM disc_model_owner.bnbpe_ibk_calib_src
WHERE cast(codmes AS int) BETWEEN 202207 AND 202505

ORDER BY 1, 2
