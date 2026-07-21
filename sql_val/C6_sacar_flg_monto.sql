-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C6_sacar_flg_monto.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C6_sacar_flg_monto.sql
--   sha256  : c04dfdcaca6d   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : flg_monto es post-decision: cuanto migra a clean si sale del AND
-- =====================================================================================
-- =====================================================================================
-- C6_sacar_flg_monto.sql | ¿que pasa si flg_monto sale del AND?
--
-- POR QUE SE PLANTEA
--   flg_monto se calcula de saldo_m0 y max_saldo: el monto que el banco DESEMBOLSO.
--   Es post-decision. Filtrar la poblacion de calibracion por el es condicionar sobre
--   el resultado de la decision que el modelo tiene que tomar.
--   Y en produccion no existe: 30_flg_clean.sql no lo incluye porque no puede.
--   Consecuencia medida en C5: monto_chico son 1,589 obs = 39% del dirty y 273
--   defaults = 53% de los defaults del bloque, y en produccion van a CLEAN.
--
-- LO QUE C5 NO PUDO VER
--   La cascada de motivo es first-match-wins y monto_chico va PRIMERO, asi que absorbe
--   a todo el que tiene flg_monto=0 aunque ademas tenga flags de riesgo. De esos 1,589
--   solo migran a CLEAN los que tienen los otros 19 EN CERO. Ese es el bloque 1.
--
-- BLOQUE 3: UNA HIPOTESIS NUEVA SOBRE LA SOBRE-PREDICCION
--   Si en 2024 la originacion se corrio hacia montos grandes, y los chicos incumplen
--   2-4x mas, entonces parte del quiebre RD 13.86% -> 4.33% es COMPOSICION POR MONTO.
--   Se descarto Impulsa, el cap y lambda. Esto no se testeo nunca.
--
-- Ventana 202207-202505, sin impulsa ni reactiva_puro.
-- ~40 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes, personeria,
         coalesce(flg_monto, 0) AS monto,
         cast(target_12m AS double) AS y,
         -- los 19, sin flg_monto
         coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0) + coalesce(flg_giro,0)
       + coalesce(flg_edad_tit,0) + coalesce(flg_edad_rl,0) + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)                       AS n_flags_17,
         coalesce(flg_pnsn,0)       AS f_pnsn,
         coalesce(flg_estado_ruc,0) AS f_ruc
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND coalesce(flg_impulsa,0) = 0 AND coalesce(flg_reactiva_puro,0) = 0
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
c AS (
  SELECT *,
         CASE WHEN monto = 1 AND n_flags_17 = 0 THEN 'A · clean hoy y manana'
              WHEN monto = 0 AND n_flags_17 = 0 THEN 'B · MIGRA a clean'
              WHEN monto = 1 AND n_flags_17 > 0 THEN 'C · dirty por riesgo/politica'
              ELSE                                   'D · dirty por ambos' END AS grupo
  FROM b
)

-- ------------------------------------------------- 1. quienes migran realmente
SELECT '1. MIGRACION' AS bloque, grupo AS detalle, personeria,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM c GROUP BY grupo, personeria

-- ------------------------------------------------- 2. el clean nuevo vs el viejo
UNION ALL
SELECT '2. CLEAN', 'clean HOY (A)', personeria,
       cast(count_if(grupo = 'A · clean hoy y manana') AS varchar),
       cast(sum(CASE WHEN grupo = 'A · clean hoy y manana' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo = 'A · clean hoy y manana' THEN y ELSE 0 END)
                / nullif(count_if(grupo = 'A · clean hoy y manana'), 0), 2) AS varchar) || ' %'
FROM c GROUP BY personeria
UNION ALL
SELECT '2. CLEAN', 'clean SIN flg_monto (A+B)', personeria,
       cast(count_if(n_flags_17 = 0) AS varchar),
       cast(sum(CASE WHEN n_flags_17 = 0 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN n_flags_17 = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_flags_17 = 0), 0), 2) AS varchar) || ' %'
FROM c GROUP BY personeria
UNION ALL
SELECT '2. CLEAN', 'dirty SIN flg_monto (C+D)', personeria,
       cast(count_if(n_flags_17 > 0) AS varchar),
       cast(sum(CASE WHEN n_flags_17 > 0 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN n_flags_17 > 0 THEN y ELSE 0 END)
                / nullif(count_if(n_flags_17 > 0), 0), 2) AS varchar) || ' %'
FROM c GROUP BY personeria

-- ------------------------------------------------- 3. composicion por monto, por anio
-- La hipotesis nueva. Si el % de monto=0 cae fuerte en 2024, parte del quiebre de RD
-- es composicion por monto y no ciclo.
UNION ALL
SELECT '3. COMPOSICION', cast(cast(codmes / 100 AS int) AS varchar), 'TODOS',
       cast(count(*) AS varchar),
       cast(round(100.0 * count_if(monto = 0) / nullif(count(*), 0), 2) AS varchar) || ' % monto=0',
       'RD ' || cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM c GROUP BY cast(codmes / 100 AS int)
UNION ALL
SELECT '3. COMPOSICION', cast(cast(codmes / 100 AS int) AS varchar) || ' · monto=0', 'TODOS',
       cast(count_if(monto = 0) AS varchar),
       cast(sum(CASE WHEN monto = 0 THEN y ELSE 0 END) AS varchar),
       'RD ' || cast(round(100.0 * sum(CASE WHEN monto = 0 THEN y ELSE 0 END)
                / nullif(count_if(monto = 0), 0), 2) AS varchar) || ' %'
FROM c GROUP BY cast(codmes / 100 AS int)
UNION ALL
SELECT '3. COMPOSICION', cast(cast(codmes / 100 AS int) AS varchar) || ' · monto=1', 'TODOS',
       cast(count_if(monto = 1) AS varchar),
       cast(sum(CASE WHEN monto = 1 THEN y ELSE 0 END) AS varchar),
       'RD ' || cast(round(100.0 * sum(CASE WHEN monto = 1 THEN y ELSE 0 END)
                / nullif(count_if(monto = 1), 0), 2) AS varchar) || ' %'
FROM c GROUP BY cast(codmes / 100 AS int)

-- ------------------------------------------------- 5. mes a mes
-- El anio promedia y puede tapar la forma. Lo que decide entre las dos explicaciones
-- del quiebre es COMO cae el % de monto=0:
--   escalon brusco  -> cambio de politica de originacion en un mes identificable
--   deriva gradual  -> cambio de mezcla de mercado
-- 35 filas.
UNION ALL
SELECT '5. POR MES', cast(codmes AS varchar), 'TODOS',
       cast(count(*) AS varchar),
       cast(count_if(monto = 0) AS varchar),
       cast(round(100.0 * count_if(monto = 0) / nullif(count(*), 0), 1) AS varchar) || ' % monto=0'
       || ' · migran ' || cast(count_if(grupo = 'B · MIGRA a clean') AS varchar)
       || ' · RD ' || cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM c GROUP BY codmes

-- ------------------------------------------------- 4. abrir sunat_knockout
-- C5 dio PNN 634 obs con RD 19.87%. Son dos flags distintos y conviene saber cual pesa.
UNION ALL
SELECT '4. SUNAT', CASE WHEN f_pnsn = 1 AND f_ruc = 1 THEN 'pnsn Y estado_ruc'
                        WHEN f_pnsn = 1 THEN 'solo flg_pnsn'
                        ELSE 'solo flg_estado_ruc' END, personeria,
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM c WHERE f_pnsn = 1 OR f_ruc = 1
GROUP BY CASE WHEN f_pnsn = 1 AND f_ruc = 1 THEN 'pnsn Y estado_ruc'
              WHEN f_pnsn = 1 THEN 'solo flg_pnsn'
              ELSE 'solo flg_estado_ruc' END, personeria

ORDER BY 1, 2, 3
