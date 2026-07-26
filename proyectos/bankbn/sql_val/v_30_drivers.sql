-- v_30_drivers.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_drivers (etapa 30)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 3b_drivers.sql: (codmes, tip_doc, key_value), heredado de mad.
--  4. 3b no se tramifica: lee mad ya completa. Correrlo antes de tiempo dispara falla_meses_incompleto.
--  5. Comparacion original vs nueva: impulsa esta agrupada por (codmes, tip_doc, key_value), asi que
--     el LEFT JOIN es 1:1 y n_filas debe coincidir exactamente con n_filas de mad (falla_vs_mad).
--  6. Se re-suman las columnas de control que el propio CTAS deja: falla_codmes_fuera_ventana,
--     falla_sin_entidad, falla_sin_tip_doc, falla_sin_segmento_reactiva, falla_impulsa_u12m_inmaduro.
--     Con la ventana 202206-202506 y horizonte 202606 las cinco deben ser 0.
--  7. Coherencia de los flags derivados: flg_impulsa <=> sld_impulsa_m0 > 0, flg_ppjj <=> tip_doc = '2'.
--  8. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, 37 AS n_meses_esp
),
base AS (
    SELECT
        CAST(t.codmes                AS VARCHAR) AS codmes,
        CAST(t.tip_doc               AS VARCHAR) AS tip_doc,
        CAST(t.key_value             AS VARCHAR) AS key_value,
        CAST(t.cod_instit_financiera AS VARCHAR) AS cod_instit_financiera,
        CAST(t.segmento_reactiva     AS VARCHAR) AS segmento_reactiva,
        t.sld_impulsa_m0,
        t.sld_impulsa_u12m,
        t.flg_impulsa,
        t.flg_impulsa_u12m,
        t.flg_ppjj,
        t.target_12m,
        t.falla_codmes_fuera_ventana,
        t.falla_sin_entidad,
        t.falla_sin_tip_doc,
        t.falla_sin_segmento_reactiva,
        t.falla_impulsa_u12m_inmaduro,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin,
        p.n_meses_esp
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers t
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
        SUM(CASE WHEN flg_impulsa      = 1 THEN 1 ELSE 0 END) AS n_impulsa_m0,
        SUM(CASE WHEN flg_impulsa_u12m = 1 THEN 1 ELSE 0 END) AS n_impulsa_u12m,
        SUM(CASE WHEN flg_ppjj         = 1 THEN 1 ELSE 0 END) AS n_ppjj,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN COALESCE(falla_codmes_fuera_ventana, 0)  = 1 THEN 1 ELSE 0 END) AS c_fuera_ventana,
        SUM(CASE WHEN COALESCE(falla_sin_entidad, 0)           = 1 THEN 1 ELSE 0 END) AS c_sin_entidad,
        SUM(CASE WHEN COALESCE(falla_sin_tip_doc, 0)           = 1 THEN 1 ELSE 0 END) AS c_sin_tip_doc,
        SUM(CASE WHEN COALESCE(falla_sin_segmento_reactiva, 0) = 1 THEN 1 ELSE 0 END) AS c_sin_segmento,
        SUM(CASE WHEN COALESCE(falla_impulsa_u12m_inmaduro, 0) = 1 THEN 1 ELSE 0 END) AS c_impulsa_inmaduro,
        SUM(CASE WHEN flg_impulsa      IS NULL OR flg_impulsa      NOT IN (0, 1)
                   OR flg_impulsa_u12m IS NULL OR flg_impulsa_u12m NOT IN (0, 1)
                   OR flg_ppjj         IS NULL OR flg_ppjj         NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                          AS c_flg_dom,
        SUM(CASE WHEN (COALESCE(flg_impulsa, 0) = 1 AND COALESCE(sld_impulsa_m0, 0) <= 0)
                   OR (COALESCE(flg_impulsa, 0) = 0 AND COALESCE(sld_impulsa_m0, 0) > 0)
                   OR (COALESCE(flg_impulsa_u12m, 0) = 1 AND COALESCE(sld_impulsa_u12m, 0) <= 0)
                   OR (COALESCE(flg_impulsa_u12m, 0) = 0 AND COALESCE(sld_impulsa_u12m, 0) > 0)
                 THEN 1 ELSE 0 END)                                          AS c_impulsa_incoh,
        SUM(CASE WHEN (COALESCE(tip_doc, '') = '2' AND COALESCE(flg_ppjj, 0) <> 1)
                   OR (COALESCE(tip_doc, '') <> '2' AND COALESCE(flg_ppjj, 0) <> 0)
                 THEN 1 ELSE 0 END)                                          AS c_ppjj_incoh,
        SUM(CASE WHEN target_12m IS NULL OR target_12m NOT IN (0, 1) THEN 1 ELSE 0 END) AS c_target_dom
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
src AS (
    SELECT COUNT(*) AS n_mad
    FROM disc_model_owner.ds_adm_bpe_bankbn_mad
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n_impulsa_m0,
    a.n_impulsa_u12m,
    a.n_ppjj,
    s.n_mad,
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
    CASE WHEN a.n_filas <> s.n_mad                   THEN 1 ELSE 0 END AS falla_vs_mad,
    CASE WHEN a.c_fuera_ventana > 0                  THEN 1 ELSE 0 END AS falla_codmes_fuera_ventana,
    CASE WHEN a.c_sin_entidad > 0                    THEN 1 ELSE 0 END AS falla_sin_entidad,
    CASE WHEN a.c_sin_tip_doc > 0                    THEN 1 ELSE 0 END AS falla_sin_tip_doc,
    CASE WHEN a.c_sin_segmento > 0                   THEN 1 ELSE 0 END AS falla_sin_segmento_reactiva,
    CASE WHEN a.c_impulsa_inmaduro > 0               THEN 1 ELSE 0 END AS falla_impulsa_u12m_inmaduro,
    CASE WHEN a.c_flg_dom > 0                        THEN 1 ELSE 0 END AS falla_flg_dominio,
    CASE WHEN a.c_impulsa_incoh > 0                  THEN 1 ELSE 0 END AS falla_impulsa_incoh,
    CASE WHEN a.c_ppjj_incoh > 0                     THEN 1 ELSE 0 END AS falla_ppjj_incoh,
    CASE WHEN a.c_target_dom > 0                     THEN 1 ELSE 0 END AS falla_target_dominio
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN src s
CROSS JOIN par p
