-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C11_giro_dentro_o_fuera.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C11_giro_dentro_o_fuera.sql
--   sha256  : 4f83777bcd1f   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : giro RD 4.83% vs clean 8.83% (0.55x, p=0.0008): NO carga riesgo, se libera del AND
-- =====================================================================================
-- =====================================================================================
-- C11_giro_dentro_o_fuera.sql | ¿flg_giro debe seguir siendo exclusion?
--
-- LA PREGUNTA
--   giro_restringido es un filtro de POLITICA COMERCIAL: la lista BPE de actividades que
--   no aceptan nuevos clientes. No es una senial de riesgo crediticio.
--   Si su RD historica es igual o menor a la del clean, excluirlo no se justifica por
--   riesgo, y meterlo adentro agranda la poblacion de aprendizaje sin contaminarla.
--   Si su RD es mayor, la exclusion se sostiene y hay que decirlo con el numero.
--
-- LO QUE YA SABEMOS, Y POR QUE NO ALCANZA
--   C9 (202503-202505): giro exclusivo 107 obs, RD 4.67% contra clean 5.43%.
--   Pero son 3 meses del regimen deprimido y 5 defaults. No decide nada.
--   C10: giro paso de 7.4% del dirty (2023T2) a 42.6% (2025T2). Su peso cambio tanto que
--   promediar toda la historia sin abrir por anio esconderia el movimiento.
--
-- POBLACION: altas TOP4, flg_ibk=1, SIN impulsa ni reactiva_puro (van a SIN BLOQUE y no
-- entran a ningun ajuste). Ventana 202207-202505, 12m de maduracion cerrada.
--
-- CUATRO GRUPOS, MUTUAMENTE EXCLUYENTES
--   CLEAN            las 20 en cero
--   GIRO solo        flg_giro=1 y las otras 19 en cero  <- los candidatos a entrar
--   GIRO + otros     flg_giro=1 y algo mas encendido    <- estos NO entran igual
--   DIRTY sin giro   flg_giro=0 y algo encendido
--
-- COMO SE DECIDE
--   Bloque 2 es el que manda: RD de "GIRO solo" contra CLEAN, por anio y pooled.
--     RD giro <= RD clean  -> la exclusion NO se justifica por riesgo. Meterlo adentro.
--     RD giro >  RD clean  -> se sostiene, y el numero es el sustento.
--   Bloque 4 dice si el scorecard YA los precifica. Si el pd_raw de giro es mas alto y
--   proporcional a su RD, meterlos adentro es seguro: el modelo los ordena solo.
--   Bloque 5 da el contrafactico: como queda el clean si se los incorpora.
--
-- ~40 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(cast(codmes AS int) / 100 AS varchar) AS anio,
         personeria, tip_doc, key_value,
         cast(target_12m AS double) AS y,
         coalesce(flg_giro,0) AS f_giro,
         CASE WHEN coalesce(flg_monto,0) = 0 THEN 1 ELSE 0 END
       + coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0)
       + coalesce(flg_edad_tit,0) + coalesce(flg_edad_rl,0) + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)          AS n_otros
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND coalesce(flg_impulsa,0) = 0 AND coalesce(flg_reactiva_puro,0) = 0
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
g AS (
  SELECT *, CASE WHEN f_giro = 0 AND n_otros = 0 THEN '1 CLEAN'
                 WHEN f_giro = 1 AND n_otros = 0 THEN '2 GIRO solo'
                 WHEN f_giro = 1                 THEN '3 GIRO + otros'
                 ELSE                                 '4 DIRTY sin giro' END AS grupo
  FROM b
),
sc AS (
  SELECT tip_doc, key_value, p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
gp AS (
  SELECT g.*, cast(sc.pd_raw AS double) AS pd_raw
  FROM g LEFT JOIN sc
    ON sc.tip_doc = g.tip_doc AND sc.key_value = g.key_value
   AND cast(g.codmes AS varchar) = cast(date_format(
         date_parse(cast(sc.p_codmes AS varchar),'%Y%m') + interval '1' month,'%Y%m') AS varchar)
)

-- ------------------------------------------------- 1. tamanio de cada grupo
SELECT '1. GRUPOS' AS bloque, grupo AS detalle, 'TODOS' AS corte,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM g GROUP BY grupo

-- ------------------------------------------------- 2. LA DECISION: giro vs clean por anio
UNION ALL
SELECT '2. GIRO vs CLEAN', anio, grupo,
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo IN ('1 CLEAN','2 GIRO solo')
GROUP BY anio, grupo

UNION ALL
SELECT '2. GIRO vs CLEAN', 'POOLED 202207-202505', grupo,
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo IN ('1 CLEAN','2 GIRO solo')
GROUP BY grupo

-- ------------------------------------------------- 3. por personeria
UNION ALL
SELECT '3. POR PERSONERIA', personeria, grupo,
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo IN ('1 CLEAN','2 GIRO solo')
GROUP BY personeria, grupo

-- ------------------------------------------------- 4. ¿el scorecard ya los precifica?
-- Si el pd_raw de giro esta en linea con su RD, meterlos adentro es seguro: el modelo
-- los ordena solo y la calibracion solo tiene que ajustar nivel.
UNION ALL
SELECT '4. pd_raw', grupo, personeria,
       cast(count_if(pd_raw IS NOT NULL) AS varchar),
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' % pd_raw',
       'RD ' || cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM gp WHERE grupo IN ('1 CLEAN','2 GIRO solo') AND pd_raw IS NOT NULL
GROUP BY grupo, personeria

-- ------------------------------------------------- 5. contrafactico
UNION ALL
SELECT '5. SI ENTRA', 'clean HOY', personeria,
       cast(count_if(grupo = '1 CLEAN') AS varchar),
       cast(sum(CASE WHEN grupo = '1 CLEAN' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo = '1 CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(grupo = '1 CLEAN'), 0), 2) AS varchar) || ' %'
FROM g GROUP BY personeria
UNION ALL
SELECT '5. SI ENTRA', 'clean + GIRO solo', personeria,
       cast(count_if(grupo IN ('1 CLEAN','2 GIRO solo')) AS varchar),
       cast(sum(CASE WHEN grupo IN ('1 CLEAN','2 GIRO solo') THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo IN ('1 CLEAN','2 GIRO solo') THEN y ELSE 0 END)
                / nullif(count_if(grupo IN ('1 CLEAN','2 GIRO solo')), 0), 2) AS varchar) || ' %'
FROM g GROUP BY personeria

-- ------------------------------------------------- 6. estabilidad del peso
-- El giro paso de 7.4% del dirty (2023T2) a 42.6% (2025T2). Si su peso no es estable,
-- la decision de incluirlo cambia la composicion de la poblacion de forma desigual por anio.
UNION ALL
SELECT '6. PESO POR ANIO', anio, 'GIRO solo / total',
       cast(count_if(grupo = '2 GIRO solo') AS varchar) || ' de ' || cast(count(*) AS varchar),
       cast(round(100.0 * count_if(grupo = '2 GIRO solo') / nullif(count(*),0), 2) AS varchar) || ' %',
       'RD giro ' || cast(round(100.0 * sum(CASE WHEN grupo = '2 GIRO solo' THEN y ELSE 0 END)
                / nullif(count_if(grupo = '2 GIRO solo'), 0), 2) AS varchar) || ' %'
FROM g GROUP BY anio

ORDER BY 1, 2, 3
