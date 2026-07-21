-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C9_mapa_exclusiones.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C9_mapa_exclusiones.sql
--   sha256  : 26d1045dd731   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : el mapa: %dirty del total y peso de cada una de las 20 exclusiones
-- =====================================================================================
-- =====================================================================================
-- C9_mapa_exclusiones.sql | el mapa completo: que se incluye, que se excluye, cuanto pesa
--
-- DECISION VIGENTE (2026-07-21): flg_monto SE MANTIENE como exclusion de APRENDIZAJE,
-- con la salvedad documentada de que monto_chico tiene RD mayor (PJJ 13.27% / PNN 20.99%
-- contra clean 8.60% / 9.11%). Ver 05_evidencia/DECISION_MONTO_CHICO.md.
-- En PRODUCCION flg_monto no se aplica (no existe antes del alta): esa asimetria queda
-- declarada, no corregida.
--
-- flg_calib_m2 = 1  <=>  flg_monto = 1  AND  las 19 exclusiones = 0
-- Aca se cuentan las 20 condiciones como exclusiones (flg_monto entra como "flg_monto=0").
--
-- TRES LECTURAS DE "CUANTO PESA CADA FILTRO", Y NO SON INTERCAMBIABLES
--   ALCANCE    el flag esta encendido, sin importar que otros tambien lo esten.
--              Suma MAS de 100% del dirty. Responde "a cuantos toca este filtro".
--   EXCLUSIVO  el flag es el UNICO encendido. Responde "a cuantos saca este filtro SOLO".
--              Es el unico numero que dice cuanto se recupera si se libera el filtro.
--   CASCADA    primer flag encendido en el orden de q3b_pdraw_dirty0.sql:12-21.
--              Suma EXACTAMENTE 100% del dirty. Es como se reporta hoy el motivo.
--   Leer ALCANCE como si fuera EXCLUSIVO sobre-estima el efecto de liberar un filtro.
--
-- DOS VENTANAS, A PROPOSITO
--   RD      202503-202505 : ultimos 3 meses con 12m de maduracion CERRADA
--   VOLUMEN 202602-202604 : ultimos 3 meses disponibles. Sin RD (no maduraron), pero es
--                           la mezcla ACTUAL, que es la que va a ver la campania.
--
-- Poblacion: flg_ibk=1, TOP4. SIN excluir impulsa/reactiva — son 2 de las 20 y se miden.
-- ~90 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes, personeria,
         cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_monto,0) = 0 THEN 1 ELSE 0 END AS f_monto,
         coalesce(flg_novig_1m_m2,0)    AS f_novig1,
         coalesce(flg_novig_12m_m2,0)   AS f_novig12,
         coalesce(flg_clasif_m2,0)      AS f_clasif,
         coalesce(flg_org_castigo_m2,0) AS f_castigo,
         coalesce(flg_org_jud_m2,0)     AS f_jud,
         coalesce(flg_org_refin_m2,0)   AS f_refin,
         coalesce(flg_org_reestr_m2,0)  AS f_reestr,
         coalesce(flg_org_atraso_m2,0)  AS f_atraso,
         coalesce(flg_org_clasif_m2,0)  AS f_orgclasif,
         coalesce(flg_impulsa,0)        AS f_impulsa,
         coalesce(flg_reactiva_puro,0)  AS f_reactiva,
         coalesce(flg_pnsn,0)           AS f_pnsn,
         coalesce(flg_estado_ruc,0)     AS f_ruc,
         coalesce(flg_giro,0)           AS f_giro,
         coalesce(flg_edad_tit,0)       AS f_edadtit,
         coalesce(flg_edad_rl,0)        AS f_edadrl,
         coalesce(flg_rrll_castigo_m2,0) AS f_rrll,
         coalesce(flg_esp_tit,0)        AS f_esptit,
         coalesce(flg_esp_cny,0)        AS f_espcny
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202503 AND 202505
),
k AS (
  SELECT *, f_monto + f_novig1 + f_novig12 + f_clasif + f_castigo + f_jud + f_refin
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
tot AS (SELECT count(*) AS n_pob, count_if(n_on >= 1) AS n_dirty FROM k)

-- ------------------------------------------------------------- 1. el embudo
SELECT '1. EMBUDO' AS bloque, 'poblacion TOP4 IBK' AS filtro,
       cast(count(*) AS varchar) AS n, '100.0 %' AS pct,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd, '' AS nota
FROM k
UNION ALL SELECT '1. EMBUDO', 'CLEAN (las 20 en cero)',
       cast(count_if(n_on = 0) AS varchar),
       cast(round(100.0 * count_if(n_on = 0) / count(*), 1) AS varchar) || ' %',
       cast(round(100.0 * sum(CASE WHEN n_on = 0 THEN y ELSE 0 END)
                / nullif(count_if(n_on = 0), 0), 2) AS varchar) || ' %', 'entra al ajuste'
FROM k
UNION ALL SELECT '1. EMBUDO', 'DIRTY (al menos una encendida)',
       cast(count_if(n_on >= 1) AS varchar),
       cast(round(100.0 * count_if(n_on >= 1) / count(*), 1) AS varchar) || ' %',
       cast(round(100.0 * sum(CASE WHEN n_on >= 1 THEN y ELSE 0 END)
                / nullif(count_if(n_on >= 1), 0), 2) AS varchar) || ' %', 'queda fuera'
FROM k
UNION ALL SELECT '1. EMBUDO', 'dirty por UNA sola condicion',
       cast(count_if(n_on = 1) AS varchar),
       cast(round(100.0 * count_if(n_on = 1) / nullif(count_if(n_on >= 1), 0), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN n_on = 1 THEN y ELSE 0 END)
                / nullif(count_if(n_on = 1), 0), 2) AS varchar) || ' %', ''
FROM k
UNION ALL SELECT '1. EMBUDO', 'dirty por DOS o mas',
       cast(count_if(n_on >= 2) AS varchar),
       cast(round(100.0 * count_if(n_on >= 2) / nullif(count_if(n_on >= 1), 0), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN n_on >= 2 THEN y ELSE 0 END)
                / nullif(count_if(n_on >= 2), 0), 2) AS varchar) || ' %', 'se solapan'
FROM k

-- ------------------------------------------------------------- 2. ALCANCE por filtro
UNION ALL
SELECT '2. ALCANCE', u.flag,
       cast(count_if(u.val = 1) AS varchar),
       cast(round(100.0 * count_if(u.val = 1) / (SELECT n_dirty FROM tot), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN u.val = 1 THEN u.y ELSE 0 END)
                / nullif(count_if(u.val = 1), 0), 2) AS varchar) || ' %',
       cast(round(100.0 * count_if(u.val = 1) / (SELECT n_pob FROM tot), 2) AS varchar) || ' % de la pob'
FROM u GROUP BY u.flag

-- ------------------------------------------------------------- 3. EXCLUSIVO por filtro
-- El unico numero que dice cuanto se RECUPERA si se libera ese filtro solo.
UNION ALL
SELECT '3. EXCLUSIVO', u.flag,
       cast(count_if(u.val = 1 AND u.n_on = 1) AS varchar),
       cast(round(100.0 * count_if(u.val = 1 AND u.n_on = 1)
                / (SELECT n_dirty FROM tot), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * sum(CASE WHEN u.val = 1 AND u.n_on = 1 THEN u.y ELSE 0 END)
                / nullif(count_if(u.val = 1 AND u.n_on = 1), 0), 2) AS varchar) || ' %',
       'si se libera, vuelven estos'
FROM u GROUP BY u.flag

-- ------------------------------------------------------------- 4. por personeria
UNION ALL
SELECT '4. POR PERSONERIA', personeria || ' · ' ||
       CASE WHEN n_on = 0 THEN 'CLEAN' ELSE 'DIRTY' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / (SELECT n_pob FROM tot), 1) AS varchar) || ' %',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %', ''
FROM k GROUP BY personeria, CASE WHEN n_on = 0 THEN 'CLEAN' ELSE 'DIRTY' END

-- ------------------------------------------------------------- 5. mezcla ACTUAL
-- Ultimos 3 meses disponibles. Sin RD: no maduraron. Es la mezcla que va a ver la campania,
-- y puede diferir mucho de la ventana de calibracion.
UNION ALL
SELECT '5. MEZCLA ACTUAL 202602-202604', 'poblacion',
       cast(count(*) AS varchar), '100.0 %', 'sin maduracion', ''
FROM disc_model_owner.bnbpe_ibk_calib_src
WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
  AND cast(codmes AS int) BETWEEN 202602 AND 202604
UNION ALL
SELECT '5. MEZCLA ACTUAL 202602-202604',
       CASE WHEN coalesce(flg_calib_m2,0) = 1 THEN 'CLEAN' ELSE 'DIRTY' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 1) AS varchar) || ' %',
       'sin maduracion', ''
FROM disc_model_owner.bnbpe_ibk_calib_src
WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
  AND cast(codmes AS int) BETWEEN 202602 AND 202604
GROUP BY CASE WHEN coalesce(flg_calib_m2,0) = 1 THEN 'CLEAN' ELSE 'DIRTY' END

ORDER BY 1, 2
