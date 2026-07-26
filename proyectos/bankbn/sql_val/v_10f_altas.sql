-- v_10f_altas.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_tmp_altas (etapa 10f)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 1t*_f_altas.sql: (codmes, tip_doc, key_value, cod_instit_financiera).
--  4. tmp_altas es DESCARTABLE POR TRAMO: correr justo despues del CREATE del tramo.
--     Ventana de par = 202206-202506 (A12 global), no la del tramo.
--  5. max_saldo filtra tipo_credito 8..10 aguas arriba: toda fila debe traer '08','09' o '10'.
--  6. alta12 / alta6 / alta2 son anidados por construccion (A-12 dentro de A-06+ dentro de A-02+).
--     n_alta2 es el driver de 10h y de 10i: si es 0, la PO sale vacia.
--  7. Duplicados al grano: GROUP BY + HAVING COUNT(*)>1.
--  8. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin
),
base AS (
    SELECT
        CAST(t.codmes                AS VARCHAR) AS codmes,
        CAST(t.tip_doc               AS VARCHAR) AS tip_doc,
        CAST(t.key_value             AS VARCHAR) AS key_value,
        CAST(t.cod_instit_financiera AS VARCHAR) AS cod_instit_financiera,
        CAST(t.tipo_credito          AS VARCHAR) AS tipo_credito,
        CAST(t.marca_entidad         AS VARCHAR) AS marca_entidad,
        CAST(t.flg_garantia          AS VARCHAR) AS flg_garantia,
        CAST(t.altas                 AS VARCHAR) AS altas,
        t.alta12,
        t.alta6,
        t.alta2,
        t.max_saldo,
        t.saldo_m0,
        t.filtro_saldo,
        t.dm_m0,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas t
    CROSS JOIN par p
),
agg AS (
    SELECT
        COUNT(*)                              AS n_filas,
        COUNT(DISTINCT codmes)                AS n_meses,
        MIN(codmes)                           AS mes_min,
        MAX(codmes)                           AS mes_max,
        MIN(mes_idx)                          AS idx_min,
        MAX(mes_idx)                          AS idx_max,
        COUNT(DISTINCT cod_instit_financiera) AS n_entidades,
        SUM(CASE WHEN alta2  = 1 THEN 1 ELSE 0 END) AS n_alta2,
        SUM(CASE WHEN alta6  = 1 THEN 1 ELSE 0 END) AS n_alta6,
        SUM(CASE WHEN alta12 = 1 THEN 1 ELSE 0 END) AS n_alta12,
        SUM(CASE WHEN filtro_saldo = 1 THEN 1 ELSE 0 END) AS n_filtro_saldo,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                   OR cod_instit_financiera IS NULL THEN 1 ELSE 0 END)        AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                           AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END)  AS c_rango,
        SUM(CASE WHEN COALESCE(tipo_credito, '') NOT IN ('08', '09', '10')
                 THEN 1 ELSE 0 END)                                           AS c_tipocred_fuera,
        SUM(CASE WHEN COALESCE(altas, '') NOT IN ('A-00', 'A-01', 'A-02', 'A-03', 'A-04', 'A-05',
                                                  'A-06', 'A-07', 'A-08', 'A-09', 'A-10', 'A-11',
                                                  'A-12', 'A-otro')
                 THEN 1 ELSE 0 END)                                           AS c_altas_dom,
        SUM(CASE WHEN (COALESCE(altas, '') = 'A-12' AND COALESCE(alta12, -1) <> 1)
                   OR (COALESCE(altas, '') <> 'A-12' AND COALESCE(alta12, -1) <> 0)
                 THEN 1 ELSE 0 END)                                           AS c_alta12_incoh,
        SUM(CASE WHEN COALESCE(alta12, 0) > COALESCE(alta6, 0)
                   OR COALESCE(alta6, 0)  > COALESCE(alta2, 0)
                 THEN 1 ELSE 0 END)                                           AS c_altas_anidado,
        SUM(CASE WHEN alta2  IS NULL OR alta2  NOT IN (0, 1)
                   OR alta6  IS NULL OR alta6  NOT IN (0, 1)
                   OR alta12 IS NULL OR alta12 NOT IN (0, 1)
                   OR filtro_saldo IS NULL OR filtro_saldo NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                           AS c_flg_dom,
        SUM(CASE WHEN COALESCE(marca_entidad, '') NOT IN ('IBK', 'OTRO') THEN 1 ELSE 0 END) AS c_marca_ent_dom,
        SUM(CASE WHEN COALESCE(flg_garantia, '') NOT IN ('01.1 Garantia Preferida',
                                                         '01. Garantia NoPreferida',
                                                         '02. Sin Garantia')
                 THEN 1 ELSE 0 END)                                           AS c_garantia_dom,
        SUM(CASE WHEN max_saldo IS NULL THEN 1 ELSE 0 END)                    AS c_maxsaldo_null,
        SUM(CASE WHEN alta2 = 1 AND COALESCE(saldo_m0, 0) <= 0 THEN 1 ELSE 0 END) AS c_alta_sin_saldo_m0
    FROM base
),
dup AS (
    SELECT
        COUNT(*)             AS n_grano_dup,
        COALESCE(SUM(n), 0)  AS n_filas_en_dup
    FROM (
        SELECT COUNT(*) AS n
        FROM base
        GROUP BY codmes, tip_doc, key_value, cod_instit_financiera
        HAVING COUNT(*) > 1
    ) d
),
cli AS (
    SELECT
        COUNT(*)                                        AS n_clientes,
        SUM(CASE WHEN con_alta2 > 0 THEN 1 ELSE 0 END)  AS n_clientes_alta2
    FROM (
        SELECT tip_doc, key_value, SUM(COALESCE(alta2, 0)) AS con_alta2
        FROM base
        GROUP BY tip_doc, key_value
    ) c
)
SELECT
    a.n_filas,
    c.n_clientes,
    c.n_clientes_alta2,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n_alta2,
    a.n_alta6,
    a.n_alta12,
    a.n_filtro_saldo,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.c_tipocred_fuera > 0                 THEN 1 ELSE 0 END AS falla_tipocred_fuera,
    CASE WHEN a.c_altas_dom > 0                      THEN 1 ELSE 0 END AS falla_altas_dominio,
    CASE WHEN a.c_alta12_incoh > 0                   THEN 1 ELSE 0 END AS falla_alta12_incoh,
    CASE WHEN a.c_altas_anidado > 0                  THEN 1 ELSE 0 END AS falla_altas_anidado,
    CASE WHEN a.c_flg_dom > 0                        THEN 1 ELSE 0 END AS falla_flg_dominio,
    CASE WHEN a.c_marca_ent_dom > 0                  THEN 1 ELSE 0 END AS falla_marca_entidad_dom,
    CASE WHEN a.c_garantia_dom > 0                   THEN 1 ELSE 0 END AS falla_garantia_dom,
    CASE WHEN a.c_maxsaldo_null > 0                  THEN 1 ELSE 0 END AS falla_maxsaldo_null,
    CASE WHEN a.c_alta_sin_saldo_m0 > 0              THEN 1 ELSE 0 END AS falla_alta_sin_saldo_m0,
    CASE WHEN a.n_alta2 = 0                          THEN 1 ELSE 0 END AS falla_sin_alta2
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
