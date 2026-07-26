-- v_10d_rcc.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc (etapa 10d)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 1t*_d_rcc.sql: (codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera).
--  4. tmp_rcc es DESCARTABLE POR TRAMO: correr justo despues del CREATE del tramo.
--     Ventana de par = 202105-202506: 202105 es la historia mas antigua que lee el tramo 1T1
--     (13 meses antes de 202206) y 202506 el ultimo mes que escribe 1T7.
--  5. La historia debe llegar a m0-13: n_meses < 14 significa que el tramo no trajo los 13m previos
--     y deuda_*_u12m_v2 quedaria trunca en 10f.
--  6. Duplicados al grano: GROUP BY + HAVING COUNT(*)>1.
--  7. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202105' AS mes_ini, '202506' AS mes_fin, 14 AS meses_min
),
base AS (
    SELECT
        CAST(t.codmes                AS VARCHAR) AS codmes,
        CAST(t.tip_doc               AS VARCHAR) AS tip_doc,
        CAST(t.key_value             AS VARCHAR) AS key_value,
        CAST(t.tipo_credito          AS VARCHAR) AS tipo_credito,
        CAST(t.cod_instit_financiera AS VARCHAR) AS cod_instit_financiera,
        t.dm,
        t.saldo_mo,
        t.saldo_m0_entidad,
        t.deuda_ins,
        t.deuda_neg,
        t.deuda_con,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin,
        p.meses_min
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc t
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
        COUNT(DISTINCT tipo_credito)          AS n_tipo_credito,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                   OR tipo_credito IS NULL OR cod_instit_financiera IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN TRY_CAST(tipo_credito AS INTEGER) IS NULL THEN 1 ELSE 0 END) AS c_tipocred_no_num,
        SUM(CASE WHEN dm < 0 THEN 1 ELSE 0 END)                              AS c_dm_neg,
        SUM(CASE WHEN saldo_mo <> 0 THEN 1 ELSE 0 END)                       AS n_con_saldo,
        SUM(CASE WHEN saldo_m0_entidad <> 0 THEN 1 ELSE 0 END)               AS n_con_saldo_ent,
        SUM(CASE WHEN COALESCE(deuda_ins, 0) <> 0
                   OR COALESCE(deuda_neg, 0) <> 0
                   OR COALESCE(deuda_con, 0) <> 0 THEN 1 ELSE 0 END)         AS n_con_deuda_tipo
    FROM base
),
dup AS (
    SELECT
        COUNT(*)             AS n_grano_dup,
        COALESCE(SUM(n), 0)  AS n_filas_en_dup
    FROM (
        SELECT COUNT(*) AS n
        FROM base
        GROUP BY codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera
        HAVING COUNT(*) > 1
    ) d
),
cli AS (
    SELECT COUNT(*) AS n_clientes
    FROM (
        SELECT tip_doc, key_value
        FROM base
        GROUP BY tip_doc, key_value
    ) c
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n_tipo_credito,
    a.n_con_saldo,
    a.n_con_saldo_ent,
    a.n_con_deuda_tipo,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.n_meses < p.meses_min                THEN 1 ELSE 0 END AS falla_hist_insuf,
    CASE WHEN a.c_tipocred_no_num > 0                THEN 1 ELSE 0 END AS falla_tipocred_no_num,
    CASE WHEN a.c_dm_neg > 0                         THEN 1 ELSE 0 END AS falla_dm_neg,
    CASE WHEN a.n_con_saldo = 0                      THEN 1 ELSE 0 END AS falla_saldo_todo_cero,
    CASE WHEN a.n_con_deuda_tipo = 0                 THEN 1 ELSE 0 END AS falla_deuda_tipo_vacia
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN par p
