-- v_10b_tag.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_tmp_tag (etapa 10b)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 1t*_b_tag.sql: (codmes, tip_doc, key_value, cod_instit_financiera).
--  4. tmp_tag es DESCARTABLE POR TRAMO: correr este archivo justo despues del CREATE del tramo.
--     Por eso la ventana de par es la global A12 (202206-202506), no la del tramo.
--  5. Duplicados al grano: GROUP BY + HAVING COUNT(*)>1 (no COUNT DISTINCT, mas barato en Trino).
--  6. n_saldo_pos es el driver de 10f (WHERE flg_saldo_pos = 1): si es 0, 10f sale vacia.
--  7. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin
),
base AS (
    SELECT
        CAST(t.codmes                AS VARCHAR) AS codmes,
        CAST(t.tip_doc               AS VARCHAR) AS tip_doc,
        CAST(t.key_value             AS VARCHAR) AS key_value,
        CAST(t.cod_instit_financiera AS VARCHAR) AS cod_instit_financiera,
        t.flg_saldo_pos,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_tag t
    CROSS JOIN par p
),
agg AS (
    SELECT
        COUNT(*)                                     AS n_filas,
        COUNT(DISTINCT codmes)                       AS n_meses,
        MIN(codmes)                                  AS mes_min,
        MAX(codmes)                                  AS mes_max,
        MIN(mes_idx)                                 AS idx_min,
        MAX(mes_idx)                                 AS idx_max,
        COUNT(DISTINCT cod_instit_financiera)        AS n_entidades,
        SUM(CASE WHEN flg_saldo_pos = 1 THEN 1 ELSE 0 END) AS n_saldo_pos,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                   OR cod_instit_financiera IS NULL THEN 1 ELSE 0 END)     AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                        AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN flg_saldo_pos IS NULL OR flg_saldo_pos NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                        AS c_flg_dom,
        SUM(CASE WHEN TRIM(COALESCE(cod_instit_financiera, '')) = '' THEN 1 ELSE 0 END) AS c_ent_vacia
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
    a.n_saldo_pos,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                              THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                          THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                           THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                           THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                         THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                              THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses     THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.c_flg_dom > 0                            THEN 1 ELSE 0 END AS falla_flg_saldo_dom,
    CASE WHEN a.c_ent_vacia > 0                          THEN 1 ELSE 0 END AS falla_entidad_vacia,
    CASE WHEN a.n_saldo_pos = 0                          THEN 1 ELSE 0 END AS falla_sin_saldo_pos
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
