-- v_10i_po.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_po (etapa 10i)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 1t*_i_po.sql: (codmes, tip_doc, key_value). 1 fila por cliente-mes tras RANK()=1.
--  4. La PO ACUMULA los 7 tramos (CREATE en 1t1_i, INSERT INTO en 1t2..1t7). falla_meses_incompleto
--     solo es exigible DESPUES del ultimo tramo. falla_gap_meses aplica en cualquier momento.
--  5. A4 desfase score: codmes_score = codmes - 1 mes. Se recalcula con indice de mes (no date_parse)
--     para que un codmes malformado no aborte la query.
--  6. Invariantes del CTAS: rank = 1, max_saldo > 0, p_codmes = codmes, alta2 = 1 cuando hubo match,
--     y ninguna fila con nombre de entidad en la lista de exclusion (Q6).
--  7. Las filas con nombre de entidad NULL ya NO sobreviven: entran en c_ent_excluida, que debe dar 0.
--  8. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, 37 AS n_meses_esp
),
base AS (
    SELECT
        CAST(t.codmes                   AS VARCHAR) AS codmes,
        CAST(t.p_codmes                 AS VARCHAR) AS p_codmes,
        CAST(t.codmes_score             AS VARCHAR) AS codmes_score,
        CAST(t.tip_doc                  AS VARCHAR) AS tip_doc,
        CAST(t.key_value                AS VARCHAR) AS key_value,
        CAST(t.cod_instit_financiera    AS VARCHAR) AS cod_instit_financiera,
        CAST(t.nombre_instit_financiera AS VARCHAR) AS nombre_instit_financiera,
        CAST(t.altas                    AS VARCHAR) AS altas,
        t.alta2,
        t.max_saldo,
        t.saldo_m0,
        t.max_saldo_ent,
        t.saldo_m0_ent,
        t.falla_entidad_alta,
        t.falla_nombre_inst,
        t."rank" AS rnk,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        TRY_CAST(SUBSTR(CAST(t.codmes_score AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes_score AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx_score,
        p.mes_ini,
        p.mes_fin,
        p.n_meses_esp
    FROM disc_model_owner.ds_adm_bpe_bankbn_po t
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
        SUM(CASE WHEN COALESCE(falla_nombre_inst, 0) = 1 THEN 1 ELSE 0 END) AS n_sin_nombre_inst,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN rnk IS NULL OR rnk <> 1 THEN 1 ELSE 0 END)             AS c_rank,
        SUM(CASE WHEN max_saldo IS NULL OR max_saldo <= 0 THEN 1 ELSE 0 END) AS c_maxsaldo,
        SUM(CASE WHEN p_codmes IS DISTINCT FROM codmes THEN 1 ELSE 0 END)    AS c_pcodmes,
        SUM(CASE WHEN mes_idx IS NULL OR mes_idx_score IS NULL
                   OR mes_idx - mes_idx_score <> 1 THEN 1 ELSE 0 END)        AS c_score_desfase,
        SUM(CASE WHEN COALESCE(falla_entidad_alta, 0) = 1 THEN 1 ELSE 0 END) AS c_sin_entidad_alta,
        SUM(CASE WHEN alta2 IS NOT NULL AND alta2 <> 1 THEN 1 ELSE 0 END)    AS c_alta2_no1,
        SUM(CASE WHEN nombre_instit_financiera IS NULL
                   OR nombre_instit_financiera IN (
                        'BANCO AGROPECUARIO', 'BANCO DE LA NACION',
                        'CAJA RURAL DE AHORRO Y CREDITO SIPAN S A', 'LEASING TOTAL S A',
                        'VALOR NO ENVIADO POR IBK')
                   OR UPPER(nombre_instit_financiera) LIKE 'BBVA CONSUMER%'
                 THEN 1 ELSE 0 END)                                          AS c_ent_excluida,
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
mes AS (
    SELECT
        MIN(n) AS n_filas_mes_min,
        MAX(n) AS n_filas_mes_max
    FROM (
        SELECT codmes, COUNT(*) AS n
        FROM base
        GROUP BY codmes
    ) m
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n_sin_nombre_inst,
    m.n_filas_mes_min,
    m.n_filas_mes_max,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.n_meses <> p.n_meses_esp             THEN 1 ELSE 0 END AS falla_meses_incompleto,
    CASE WHEN a.c_rank > 0                           THEN 1 ELSE 0 END AS falla_rank_no1,
    CASE WHEN a.c_maxsaldo > 0                       THEN 1 ELSE 0 END AS falla_maxsaldo_no_pos,
    CASE WHEN a.c_pcodmes > 0                        THEN 1 ELSE 0 END AS falla_pcodmes,
    CASE WHEN a.c_score_desfase > 0                  THEN 1 ELSE 0 END AS falla_codmes_score_a4,
    CASE WHEN a.c_sin_entidad_alta > 0               THEN 1 ELSE 0 END AS falla_sin_entidad_alta,
    CASE WHEN a.c_alta2_no1 > 0                      THEN 1 ELSE 0 END AS falla_alta2_no1,
    CASE WHEN a.c_ent_excluida > 0                   THEN 1 ELSE 0 END AS falla_entidad_excluida,
    CASE WHEN a.c_ent_vacia > 0                      THEN 1 ELSE 0 END AS falla_entidad_vacia
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN mes m
CROSS JOIN par p
