-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C9_mapa_exclusiones.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C9_mapa_exclusiones.sql
--   sha256  : 32c8290d4fe1   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : el mapa: %dirty del total y peso de cada una de las 20 exclusiones
-- =====================================================================================
-- =====================================================================================
-- C9_mapa_exclusiones.sql | el mapa: que entra a cada bloque y cuanto pesa cada filtro
--
-- CORREGIDO 2026-07-21. El ruteo tiene TRES salidas, no dos:
--   CLEAN       flg_calib_m2 = 1                                    -> cadena clean
--               q3_pdraw_tri_desfase.sql:33
--   DIRTY       flg_calib_m2 = 0 AND impulsa = 0 AND reactiva_puro = 0  -> cadena dirty
--               q3b_pdraw_dirty0.sql:36-37  ("SIN garantizados ... excluidos por
--               politica/perfil, NO por programa")
--   SIN BLOQUE  impulsa = 1 OR reactiva_puro = 1                    -> NINGUNA
--               No entra a ningun ajuste. En produccion se puntua con coeficientes
--               extrapolados del clean.
--
-- La v1 de esta consulta equiparaba DIRTY con flg_calib_m2 = 0 y metia a Impulsa
-- adentro. Impulsa no participa de ningun ajuste, asi que contarlo como dirty inflaba
-- el bloque y contaminaba su RD.
--
-- DECISION VIGENTE: flg_monto se MANTIENE como exclusion de aprendizaje, con la RD
-- mayor documentada como salvedad (05_evidencia/DECISION_MONTO_CHICO.md). En produccion
-- no se aplica: esa asimetria queda declarada, no corregida.
--
-- TRES LECTURAS DE "CUANTO PESA CADA FILTRO", Y NO SON INTERCAMBIABLES
--   ALCANCE    el flag esta encendido, sin importar que otros tambien. Suma >100%.
--   EXCLUSIVO  el flag es el UNICO encendido. Es el unico numero que dice cuanto se
--              recupera si se libera ese filtro solo.
--   Leer ALCANCE como EXCLUSIVO sobre-estima el efecto de liberar un filtro.
--   Los bloques 2 y 3 se miden sobre el DIRTY REAL: ya sin programa.
--
-- DOS VENTANAS, A PROPOSITO
--   RD      202503-202505 : ultimos 3 con 12m de maduracion CERRADA
--   VOLUMEN 202602-202604 : ultimos 3 disponibles. Sin RD, pero es la mezcla ACTUAL.
--   OJO: 202503-202505 cae en el regimen deprimido post-202408 (RD global ~4.8% contra
--   ~12.9% en 202207-202303). Las RD de aqui NO son comparables con la ventana larga,
--   y con n chico los flags de baja frecuencia dan 0 por frecuencia, no por inexistencia.
--
-- Poblacion: flg_ibk = 1, TOP4.
-- ~90 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes, personeria,
         cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_monto,0) = 0 THEN 1 ELSE 0 END AS f_monto,
         coalesce(flg_novig_1m_m2,0)     AS f_novig1,
         coalesce(flg_novig_12m_m2,0)    AS f_novig12,
         coalesce(flg_clasif_m2,0)       AS f_clasif,
         coalesce(flg_org_castigo_m2,0)  AS f_castigo,
         coalesce(flg_org_jud_m2,0)      AS f_jud,
         coalesce(flg_org_refin_m2,0)    AS f_refin,
         coalesce(flg_org_reestr_m2,0)   AS f_reestr,
         coalesce(flg_org_atraso_m2,0)   AS f_atraso,
         coalesce(flg_org_clasif_m2,0)   AS f_orgclasif,
         coalesce(flg_impulsa,0)         AS f_impulsa,
         coalesce(flg_reactiva_puro,0)   AS f_reactiva,
         coalesce(flg_pnsn,0)            AS f_pnsn,
         coalesce(flg_estado_ruc,0)      AS f_ruc,
         coalesce(flg_giro,0)            AS f_giro,
         coalesce(flg_edad_tit,0)        AS f_edadtit,
         coalesce(flg_edad_rl,0)         AS f_edadrl,
         coalesce(flg_rrll_castigo_m2,0) AS f_rrll,
         coalesce(flg_esp_tit,0)         AS f_esptit,
         coalesce(flg_esp_cny,0)         AS f_espcny
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202503 AND 202505
),
k AS (
  SELECT *,
         CASE WHEN f_impulsa = 1 OR f_reactiva = 1 THEN 1 ELSE 0 END AS fuera,
         f_monto + f_novig1 + f_novig12 + f_clasif + f_castigo + f_jud + f_refin
       + f_reestr + f_atraso + f_orgclasif + f_impulsa + f_reactiva + f_pnsn + f_ruc
       + f_giro + f_edadtit + f_edadrl + f_rrll + f_esptit + f_espcny AS n_on
  FROM b
),
u AS (
  SELECT k.*, t.flag, t.val
  FROM k CROSS JOIN UNNEST(
    ARRAY['01 monto (flg_monto=0)','02 novig_1m_m2','03 novig_12m_m2','04 clasif_m2',
          '05 org_castigo_m2','06 org_jud_m2','07 org_refin_m2','08 org_reestr_m2',
          '09 org_atraso_m2','10 org_clasif_m2','11 impulsa','12 reactiva_puro',
          '13 pnsn','14 estado_ruc','15 giro','16 edad_tit','17 edad_rl',
          '18 rrll_castigo_m2','19 esp_tit','20 esp_cny'],
    ARRAY[f_monto, f_novig1, f_novig12, f_clasif, f_castigo, f_jud, f_refin, f_reestr,
          f_atraso, f_orgclasif, f_impulsa, f_reactiva, f_pnsn, f_ruc, f_giro,
          f_edadtit, f_edadrl, f_rrll, f_esptit, f_espcny]
  ) AS t(flag, val)
),
-- n_dirty es el DIRTY REAL: sin programa. Denominador de los bloques 2 y 3.
tot AS (
  SELECT count(*) AS n_pob, count_if(n_on >= 1 AND fuera = 0) AS n_dirty FROM k
)

-- ------------------------------------------------------------- 1. las tres salidas
SELECT '1. EMBUDO' AS bloque, 'poblacion TOP4 IBK' AS filtro,
       cast(count(*) AS varchar) AS n, '100.0 %' AS pct,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd, '' AS nota
FROM k
UNION ALL SELECT '1. EMBUDO', 'CLEAN (las 20 en cero)',
       cast(count_if(n_on = 0) AS varchar),
       cast(round(100.0 * count_if(n_on = 0) / count(*), 1) AS varchar) || ' %',
       cast(round(100.0 * sum(CASE WHEN n_on = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_on = 0), 0), 2) AS varchar) || ' %', 'cadena clean'
FROM k
UNION ALL SELECT '1. EMBUDO', 'DIRTY real (calib=0, SIN programa)',
       cast(count_if(n_on >= 1 AND fuera = 0) AS varchar),
       cast(round(100.0 * count_if(n_on >= 1 AND fuera = 0) / count(*), 1) AS varchar) || ' %',
       cast(round(100.0 * sum(CASE WHEN n_on >= 1 AND fuera = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_on >= 1 AND fuera = 0), 0), 2) AS varchar) || ' %', 'cadena dirty'
FROM k
UNION ALL SELECT '1. EMBUDO', 'SIN BLOQUE (impulsa / reactiva_puro)',
       cast(count_if(fuera = 1) AS varchar),
       cast(round(100.0 * count_if(fuera = 1) / count(*), 1) AS varchar) || ' %',
       cast(round(100.0 * sum(CASE WHEN fuera = 1 THEN y ELSE 0 END)
                / nullif(count_if(fuera = 1), 0), 2) AS varchar) || ' %',
       'no entra a ningun ajuste; en produccion se puntua extrapolado'
FROM k
UNION ALL SELECT '1. EMBUDO', 'dirty real por UNA sola condicion',
       cast(count_if(n_on = 1 AND fuera = 0) AS varchar),
       cast(round(100.0 * count_if(n_on = 1 AND fuera = 0)
                / nullif(count_if(n_on >= 1 AND fuera = 0), 0), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN n_on = 1 AND fuera = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_on = 1 AND fuera = 0), 0), 2) AS varchar) || ' %', ''
FROM k
UNION ALL SELECT '1. EMBUDO', 'dirty real por DOS o mas',
       cast(count_if(n_on >= 2 AND fuera = 0) AS varchar),
       cast(round(100.0 * count_if(n_on >= 2 AND fuera = 0)
                / nullif(count_if(n_on >= 1 AND fuera = 0), 0), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN n_on >= 2 AND fuera = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_on >= 2 AND fuera = 0), 0), 2) AS varchar) || ' %', 'se solapan'
FROM k

-- ------------------------------------------------------------- 2. ALCANCE, sobre el dirty real
UNION ALL
SELECT '2. ALCANCE', u.flag,
       cast(count_if(u.val = 1 AND u.fuera = 0) AS varchar),
       cast(round(100.0 * count_if(u.val = 1 AND u.fuera = 0)
                / (SELECT n_dirty FROM tot), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN u.val = 1 AND u.fuera = 0 THEN u.y ELSE 0 END)
                / nullif(count_if(u.val = 1 AND u.fuera = 0), 0), 2) AS varchar) || ' %',
       cast(round(100.0 * count_if(u.val = 1) / (SELECT n_pob FROM tot), 2) AS varchar)
       || ' % de la pob total'
FROM u GROUP BY u.flag

-- ------------------------------------------------------------- 3. EXCLUSIVO, sobre el dirty real
UNION ALL
SELECT '3. EXCLUSIVO', u.flag,
       cast(count_if(u.val = 1 AND u.n_on = 1 AND u.fuera = 0) AS varchar),
       cast(round(100.0 * count_if(u.val = 1 AND u.n_on = 1 AND u.fuera = 0)
                / (SELECT n_dirty FROM tot), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN u.val = 1 AND u.n_on = 1 AND u.fuera = 0 THEN u.y ELSE 0 END)
                / nullif(count_if(u.val = 1 AND u.n_on = 1 AND u.fuera = 0), 0), 2) AS varchar) || ' %',
       'si se libera, vuelven estos'
FROM u GROUP BY u.flag

-- ------------------------------------------------------------- 4. las tres salidas x personeria
UNION ALL
SELECT '4. POR PERSONERIA',
       personeria || ' - ' || CASE WHEN n_on = 0 THEN 'CLEAN'
                                   WHEN fuera = 1 THEN 'SIN BLOQUE'
                                   ELSE 'DIRTY real' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / (SELECT n_pob FROM tot), 1) AS varchar) || ' %',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %', ''
FROM k
GROUP BY personeria, CASE WHEN n_on = 0 THEN 'CLEAN'
                          WHEN fuera = 1 THEN 'SIN BLOQUE'
                          ELSE 'DIRTY real' END

-- ------------------------------------------------------------- 5. la mezcla ACTUAL
UNION ALL
SELECT '5. MEZCLA ACTUAL 202602-202604',
       CASE WHEN coalesce(flg_calib_m2,0) = 1 THEN 'CLEAN'
            WHEN coalesce(flg_impulsa,0) = 1 OR coalesce(flg_reactiva_puro,0) = 1
                 THEN 'SIN BLOQUE'
            ELSE 'DIRTY real' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 1) AS varchar) || ' %',
       'sin maduracion', 'la mezcla que vera la campania'
FROM disc_model_owner.bnbpe_ibk_calib_src
WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
  AND cast(codmes AS int) BETWEEN 202602 AND 202604
GROUP BY CASE WHEN coalesce(flg_calib_m2,0) = 1 THEN 'CLEAN'
              WHEN coalesce(flg_impulsa,0) = 1 OR coalesce(flg_reactiva_puro,0) = 1
                   THEN 'SIN BLOQUE'
              ELSE 'DIRTY real' END

ORDER BY 1, 2
