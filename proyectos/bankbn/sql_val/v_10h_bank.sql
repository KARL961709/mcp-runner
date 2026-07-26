-- v_10h_bank.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_tmp_bank (etapa 10h)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 1t*_h_bank.sql: (codmes, tip_doc, key_value). Lado SISTEMA (sin filtro de entidad).
--  4. tmp_bank es DESCARTABLE POR TRAMO: correr justo despues del CREATE del tramo, con tmp_altas
--     del MISMO tramo todavia en disco (falla_vs_altas la compara contra ella).
--  5. Comparacion original vs nueva: el driver de 10h es (codmes, tip_doc, key_value) de tmp_altas
--     con alta2 = 1. n_filas debe coincidir exactamente con n_altas_alta2.
--  6. max_saldo = greatest(saldo_m1..saldo_m12) se recalcula aqui con IS DISTINCT FROM (null-safe).
--  7. n_maxsaldo_pos es el driver de 10i (WHERE a.max_saldo > 0): si es 0, la PO sale vacia.
--  8. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin
),
base AS (
    SELECT
        CAST(t.codmes    AS VARCHAR) AS codmes,
        CAST(t.tip_doc   AS VARCHAR) AS tip_doc,
        CAST(t.key_value AS VARCHAR) AS key_value,
        t.saldo_m0,  t.saldo_m1,  t.saldo_m2,  t.saldo_m3,
        t.saldo_m4,  t.saldo_m5,  t.saldo_m6,  t.saldo_m7,
        t.saldo_m8,  t.saldo_m9,  t.saldo_m10, t.saldo_m11,
        t.saldo_m12, t.max_saldo,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_bank t
    CROSS JOIN par p
),
agg AS (
    SELECT
        COUNT(*)               AS n_filas,
        COUNT(DISTINCT codmes) AS n_meses,
        MIN(codmes)            AS mes_min,
        MAX(codmes)            AS mes_max,
        MIN(mes_idx)           AS idx_min,
        MAX(mes_idx)           AS idx_max,
        SUM(CASE WHEN max_saldo > 0 THEN 1 ELSE 0 END)     AS n_maxsaldo_pos,
        SUM(CASE WHEN saldo_m0 > 0 THEN 1 ELSE 0 END)      AS n_saldo_m0_pos,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN saldo_m0  IS NULL OR saldo_m1  IS NULL OR saldo_m2  IS NULL
                   OR saldo_m3  IS NULL OR saldo_m4  IS NULL OR saldo_m5  IS NULL
                   OR saldo_m6  IS NULL OR saldo_m7  IS NULL OR saldo_m8  IS NULL
                   OR saldo_m9  IS NULL OR saldo_m10 IS NULL OR saldo_m11 IS NULL
                   OR saldo_m12 IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_saldo_null,
        SUM(CASE WHEN max_saldo IS DISTINCT FROM greatest(saldo_m1, saldo_m2, saldo_m3, saldo_m4,
                                                          saldo_m5, saldo_m6, saldo_m7, saldo_m8,
                                                          saldo_m9, saldo_m10, saldo_m11, saldo_m12)
                 THEN 1 ELSE 0 END)                                          AS c_maxsaldo_incoh
    FROM base
),
dup AS (
    SELECT
        COUNT(*)             AS n_grano_dup,
        COALESCE(SUM(n), 0)  AS n_filas_en_dup
    FROM (
        SELECT COUNT(*) AS n
        FROM base
        GROUP BY codmes, tip_doc, key_value
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
),
drv AS (
    SELECT COUNT(*) AS n_altas_alta2
    FROM (
        SELECT codmes, tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas
        WHERE alta2 = 1
        GROUP BY codmes, tip_doc, key_value
    ) x
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_maxsaldo_pos,
    a.n_saldo_m0_pos,
    v.n_altas_alta2,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.c_saldo_null > 0                     THEN 1 ELSE 0 END AS falla_saldo_null,
    CASE WHEN a.c_maxsaldo_incoh > 0                 THEN 1 ELSE 0 END AS falla_maxsaldo_incoh,
    CASE WHEN a.n_filas <> v.n_altas_alta2           THEN 1 ELSE 0 END AS falla_vs_altas,
    CASE WHEN a.n_maxsaldo_pos = 0                   THEN 1 ELSE 0 END AS falla_sin_maxsaldo_pos
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN drv v
