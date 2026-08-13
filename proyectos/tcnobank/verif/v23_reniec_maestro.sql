-- ============================================================================
-- V23. EL MAESTRO RENIEC ES SNAPSHOT - CONTRATO FISICO Y SESGO DE COBERTURA
--   scan: t_mst_reniec_rsk U information_schema.columns U cal
--   60_filtros linea 106 une el maestro SIN periodo. Dos cosas que eso obliga a medir
--   corte A unicidad por llave. Un join sin periodo contra un maestro con mas de una
--          fila por persona multiplica la PO entera en silencio, y ningun gate lo ve.
--          n_llaves_dup > 0 es el hallazgo: dice cuantas personas traen mas de una fila
--   corte B las columnas del maestro. Si hay una de periodo o de fecha de carga, el
--          join la esta ignorando y el snapshot es evitable, no estructural
--   corte C nomatch por tipo de documento y tramo. Separa las dos causas del alza de
--          0.48 a 1.29 por ciento: rezago de carga del maestro contra cambio de mezcla
--          de documento. Si sube parejo en todo tip_doc es rezago. Si sube solo donde
--          crece la participacion de un tip_doc, es mezcla
--   no sale ninguna llave, solo conteos
-- ============================================================================
WITH k AS (
    SELECT tip_doc,
           key_value,
           count(*)                                                                     AS n_filas_llave,
           sum(CASE WHEN fec_nacimiento IS NULL THEN 1 ELSE 0 END)                      AS n_sin_fecha
    FROM e_perm_aws.t_mst_reniec_rsk
    GROUP BY tip_doc, key_value
),
m AS (
    SELECT sum(n_filas_llave)                                                           AS n_filas,
           count(*)                                                                     AS n_llaves,
           sum(CASE WHEN n_filas_llave > 1 THEN 1 ELSE 0 END)                           AS n_llaves_dup,
           max(n_filas_llave)                                                           AS max_filas_llave,
           sum(n_sin_fecha)                                                             AS n_sin_fecha
    FROM k
),
a AS (
    SELECT 'A.maestro'                                                                  AS corte,
           d                                                                            AS dim,
           ''                                                                           AS grupo,
           v                                                                            AS n,
           round(100.0 * v / CAST(nullif(m.n_filas, 0) AS DOUBLE), 4)                   AS pct
    FROM m
    CROSS JOIN UNNEST(ARRAY['1.filas', '2.llaves distintas', '3.llaves duplicadas',
                            '4.max filas por llave', '5.filas sin fec_nacimiento'],
                      ARRAY[m.n_filas, m.n_llaves, m.n_llaves_dup,
                            m.max_filas_llave, m.n_sin_fecha]) AS t (d, v)
),
b AS (
    SELECT 'B.columnas'                                                                 AS corte,
           column_name                                                                  AS dim,
           data_type                                                                    AS grupo,
           CAST(ordinal_position AS BIGINT)                                             AS n,
           CAST(NULL AS DOUBLE)                                                         AS pct
    FROM information_schema.columns
    WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_reniec_rsk'
),
c AS (
    SELECT 'C.nomatch'                                                                  AS corte,
           CAST(tip_doc AS VARCHAR)                                                     AS dim,
           CASE WHEN codmes_mrm <= '202012' THEN '1.hasta 2020'
                WHEN codmes_mrm <= '202212' THEN '2.2021 a 2022'
                WHEN codmes_mrm <= '202412' THEN '3.2023 a 2024'
                ELSE '4.2025 a 2026' END                                                AS grupo,
           count(*)                                                                     AS n,
           round(100.0 * avg(CAST(f_edad_nomatch AS DOUBLE)), 4)                        AS pct
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    GROUP BY CAST(tip_doc AS VARCHAR),
             CASE WHEN codmes_mrm <= '202012' THEN '1.hasta 2020'
                  WHEN codmes_mrm <= '202212' THEN '2.2021 a 2022'
                  WHEN codmes_mrm <= '202412' THEN '3.2023 a 2024'
                  ELSE '4.2025 a 2026' END
)
SELECT corte, dim, grupo, n, pct FROM a
UNION ALL
SELECT corte, dim, grupo, n, pct FROM b
UNION ALL
SELECT corte, dim, grupo, n, pct FROM c
ORDER BY corte, dim, grupo
