-- ============================================================================
-- V22. LA MARCA DE EDAD - SEMANTICA, ERROR DE CLASIFICACION Y SPLIT 21 / 75
--   scan: cal U t_mst_reniec_rsk
--   60_filtros linea 61 usa date_diff('year', nac, ref). Si Trino trunca al ano, eso
--          NO es edad cumplida sino year(ref) - year(nac), y sobreestima hasta en 1 ano
--          a quien todavia no cumplio. Sacaria a gente de 75 que si esta en politica y
--          dejaria pasar a gente de 20 que no. Las dos contaminaciones van en la
--          direccion que hace ver al grupo marcado MENOS riesgoso que el clean
--   corte 0 semantica con fechas literales. Decide la pregunta antes que cualquier
--          conteo: si edad_dd = edad_real en los cuatro casos, la marca esta bien y
--          todo el resto de este archivo es descriptivo
--   corte A entidad por grupo sobre la base de calibracion
--   corte B anio por grupo sobre toda la historia, para el salto de 2026
--   corte C distribucion de edad_real del tramo joven. Menor de 18 NO es exclusion de
--          politica, es defecto de dato: no puede haber tarjeta. Va aparte
--   corte D el tramo joven de IBK por nodo contra el clean por nodo. En IBK el menor de
--          21 corre 8.16 contra 10.54 del clean, al reves que en las otras cuatro
--          entidades. Si se concentra en N1, la brecha es composicion y no edad
--   n_mal_marcado  marcado fuera de rango pero con edad real DENTRO  -> sale mal a dirty
--   n_no_marcado   no marcado pero con edad real FUERA               -> se queda mal en clean
--   grupo 3 debe salir en cero por construccion: f_edad_rango lleva coalesce a 0, o sea
--          sin fecha no dispara. Si sale distinto de cero, el filtro no es lo que creemos
--   ancla k=0 contra el dia 01 de codmes_mrm, igual que el build. No se corrige aca: es
--          otra desviacion y se mide por separado
-- ============================================================================
WITH b AS (
    SELECT c.entidad,
           substr(c.codmes_mrm, 1, 4)                                                   AS anio,
           c.codmes_mrm,
           c.flg_clean,
           c.target_12m,
           c.f_edad_rango,
           c.nodo_final,
           c.f_cast_ori + c.f_jud_ori + c.f_ref_ori + c.f_ree_ori + c.f_malo_ori
         + c.f_cast_u24m + c.f_jud_u24m + c.f_ref_u6m + c.f_mayor_cpp + c.f_gar_conv
         + c.f_fraude + c.f_swap_u12m                                                   AS otros_12,
           CAST(r.fec_nacimiento AS DATE)                                               AS nac,
           CAST(date_parse(c.codmes_mrm || '01', '%Y%m%d') AS DATE)                     AS ref
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk r
           ON r.tip_doc = c.tip_doc AND r.key_value = c.id_value
    WHERE c.flg_clean <> 99
),
e AS (
    SELECT entidad, anio, codmes_mrm, flg_clean, target_12m, f_edad_rango, otros_12, nodo_final,
           date_diff('year', nac, ref)                                                  AS edad_dd,
           date_diff('year', nac, ref)
         - CASE WHEN month(ref) < month(nac)
                  OR (month(ref) = month(nac) AND day(ref) < day(nac))
                THEN 1 ELSE 0 END                                                       AS edad_real
    FROM b
),
g AS (
    SELECT entidad, anio, codmes_mrm, target_12m, edad_dd, edad_real, f_edad_rango, nodo_final,
           CASE WHEN flg_clean = 1                                          THEN '0.clean de referencia'
                WHEN f_edad_rango = 1 AND otros_12 = 0 AND edad_dd < 21     THEN '1.solo edad menor de 21'
                WHEN f_edad_rango = 1 AND otros_12 = 0 AND edad_dd > 75     THEN '2.solo edad mayor de 75'
                WHEN f_edad_rango = 1 AND otros_12 = 0                      THEN '3.solo edad sin fecha'
                WHEN f_edad_rango = 1                                       THEN '4.edad mas otro filtro'
                ELSE '5.dirty sin edad' END                                             AS grupo
    FROM e
),
ctl AS (
    SELECT '0.semantica'                                                                AS corte,
           caso                                                                         AS dim,
           'edad real esperada ' || CAST(esp AS VARCHAR)                                AS grupo,
           CAST(date_diff('year', dnac, dref) AS BIGINT)                                      AS n,
           CAST(NULL AS BIGINT)                                                         AS n_maduro,
           CAST(NULL AS BIGINT)                                                         AS n_malo,
           CAST(NULL AS DOUBLE)                                                         AS rd_12m,
           CAST(NULL AS BIGINT)                                                         AS n_mal_marcado,
           CAST(NULL AS BIGINT)                                                         AS n_no_marcado,
           date_diff('year', dnac, dref)                                                      AS edad_dd_min,
           date_diff('year', dnac, dref)                                                      AS edad_dd_max,
           CAST(esp AS BIGINT)                                                          AS edad_real_min,
           CAST(esp AS BIGINT)                                                          AS edad_real_max
    FROM UNNEST(ARRAY['1.nac 1950-12-15 ref 2026-01-01 no cumplio',
                      '2.nac 1950-01-15 ref 2026-01-01 no cumplio',
                      '3.nac 2005-06-15 ref 2026-01-01 no cumplio',
                      '4.nac 2005-01-01 ref 2026-01-01 ya cumplio'],
                ARRAY[DATE '1950-12-15', DATE '1950-01-15', DATE '2005-06-15', DATE '2005-01-01'],
                ARRAY[DATE '2026-01-01', DATE '2026-01-01', DATE '2026-01-01', DATE '2026-01-01'],
                ARRAY[75, 75, 20, 21]) AS t (caso, dnac, dref, esp)
)
SELECT corte, dim, grupo, n, n_maduro, n_malo, rd_12m,
       n_mal_marcado, n_no_marcado, edad_dd_min, edad_dd_max, edad_real_min, edad_real_max
FROM ctl
UNION ALL
SELECT 'A.entidad'                                                                      AS corte,
       entidad                                                                          AS dim,
       grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       sum(CASE WHEN f_edad_rango = 1 AND edad_real BETWEEN 21 AND 75
                THEN 1 ELSE 0 END)                                                      AS n_mal_marcado,
       sum(CASE WHEN f_edad_rango = 0 AND edad_real IS NOT NULL
                 AND NOT (edad_real BETWEEN 21 AND 75) THEN 1 ELSE 0 END)               AS n_no_marcado,
       min(edad_dd)                                                                     AS edad_dd_min,
       max(edad_dd)                                                                     AS edad_dd_max,
       min(edad_real)                                                                   AS edad_real_min,
       max(edad_real)                                                                   AS edad_real_max
FROM g
WHERE codmes_mrm BETWEEN '202303' AND '202506'
GROUP BY entidad, grupo
UNION ALL
SELECT 'B.anio'                                                                         AS corte,
       anio                                                                             AS dim,
       grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       sum(CASE WHEN f_edad_rango = 1 AND edad_real BETWEEN 21 AND 75
                THEN 1 ELSE 0 END)                                                      AS n_mal_marcado,
       sum(CASE WHEN f_edad_rango = 0 AND edad_real IS NOT NULL
                 AND NOT (edad_real BETWEEN 21 AND 75) THEN 1 ELSE 0 END)               AS n_no_marcado,
       min(edad_dd)                                                                     AS edad_dd_min,
       max(edad_dd)                                                                     AS edad_dd_max,
       min(edad_real)                                                                   AS edad_real_min,
       max(edad_real)                                                                   AS edad_real_max
FROM g
GROUP BY anio, grupo
UNION ALL
SELECT 'C.edad joven'                                                                   AS corte,
       entidad                                                                          AS dim,
       CASE WHEN edad_real IS NULL THEN '9.sin fecha'
            WHEN edad_real < 15    THEN '1.menor de 15'
            WHEN edad_real < 18    THEN '2.de 15 a 17'
            WHEN edad_real = 18    THEN '3.de 18'
            WHEN edad_real = 19    THEN '4.de 19'
            WHEN edad_real = 20    THEN '5.de 20'
            ELSE '6.de 21 o mas, mal marcado' END                                       AS grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       CAST(NULL AS BIGINT)                                                             AS n_mal_marcado,
       CAST(NULL AS BIGINT)                                                             AS n_no_marcado,
       min(edad_dd)                                                                     AS edad_dd_min,
       max(edad_dd)                                                                     AS edad_dd_max,
       min(edad_real)                                                                   AS edad_real_min,
       max(edad_real)                                                                   AS edad_real_max
FROM g
WHERE grupo = '1.solo edad menor de 21'
GROUP BY entidad,
         CASE WHEN edad_real IS NULL THEN '9.sin fecha'
              WHEN edad_real < 15    THEN '1.menor de 15'
              WHEN edad_real < 18    THEN '2.de 15 a 17'
              WHEN edad_real = 18    THEN '3.de 18'
              WHEN edad_real = 19    THEN '4.de 19'
              WHEN edad_real = 20    THEN '5.de 20'
              ELSE '6.de 21 o mas, mal marcado' END
UNION ALL
SELECT 'D.nodo ibk'                                                                     AS corte,
       coalesce(nodo_final, 'SIN_NODO')                                                 AS dim,
       grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       CAST(NULL AS BIGINT)                                                             AS n_mal_marcado,
       CAST(NULL AS BIGINT)                                                             AS n_no_marcado,
       min(edad_dd)                                                                     AS edad_dd_min,
       max(edad_dd)                                                                     AS edad_dd_max,
       min(edad_real)                                                                   AS edad_real_min,
       max(edad_real)                                                                   AS edad_real_max
FROM g
WHERE entidad = '00002'
  AND grupo IN ('0.clean de referencia', '1.solo edad menor de 21')
GROUP BY coalesce(nodo_final, 'SIN_NODO'), grupo
ORDER BY corte, dim, grupo
