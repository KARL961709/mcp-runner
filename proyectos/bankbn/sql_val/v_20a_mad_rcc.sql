-- v_20a_mad_rcc.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc (etapa 20a)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 2t*_b_mad_rcc.sql: (codmes, tip_doc, key_value).
--  4. tmp_mad_rcc es DESCARTABLE POR TRAMO: correr justo despues del CREATE del tramo.
--     Ventana de par = 202206-202506 (A12 global), no la del tramo.
--  5. Q1: las ventanas de 12m contienen a las de 6m, de modo que dias_atraso_12m >= dias_atraso_9m
--     >= dias_atraso_6m y jud/cast/ref/ree/ven_12um >= *_06um. falla_q1_ventana_monot detecta la
--     inversion. falla_q1_12m_igual_6m detecta el bug viejo (12m copiando literalmente las de 6m):
--     si NINGUNA fila tiene 12m estrictamente mayor que 6m, las ventanas son la misma.
--  6. A7: las columnas *_m2 (m0-2) deben venir pobladas. n_con_m2 = 0 significa que el bloque m-2
--     no se calculo y 40_cal quedaria sin insumo para los filtros de CASO2.
--  7. Invariantes del CTAS: saldo_vig_m0 > 0 (WHERE final) y ent_alta = cod_instit_financiera.
--  8. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin
),
base AS (
    SELECT
        CAST(t.codmes                   AS VARCHAR) AS codmes,
        CAST(t.tip_doc                  AS VARCHAR) AS tip_doc,
        CAST(t.key_value                AS VARCHAR) AS key_value,
        CAST(t.ent_alta                 AS VARCHAR) AS ent_alta,
        CAST(t.cod_instit_financiera    AS VARCHAR) AS cod_instit_financiera,
        CAST(t.nombre_instit_financiera AS VARCHAR) AS nombre_instit_financiera,
        CAST(t.flg_garantia             AS VARCHAR) AS flg_garantia,
        CAST(t.clasificacion_m0         AS VARCHAR) AS clasificacion_m0,
        CAST(t.clasificacion_m2         AS VARCHAR) AS clasificacion_m2,
        t.saldo_vig_m0,
        t.saldo_vig_m2,
        t.saldo_cast_m2,
        t.saldo_jud_m2,
        t.saldo_ref_m2,
        t.saldo_rest_m2,
        t.dm_fm0,
        t.dm_org_m2,
        t.dias_atraso_6m,
        t.dias_atraso_9m,
        t.dias_atraso_12m,
        t.jud_06um,  t.jud_12um,
        t.cast_06um, t.cast_12um,
        t.ref_06um,  t.ref_12um,
        t.ree_06um,  t.ree_12um,
        t.ven_06um,  t.ven_12um,
        t.nro_miss06,
        t.nro_miss09,
        t.nro_miss12,
        t.flg_reactiva,
        t.flg_solo_reactiva,
        t.flag_cons,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc t
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
        SUM(CASE WHEN dias_atraso_12m IS NOT NULL
                  AND (dias_atraso_6m IS NULL OR dias_atraso_12m > dias_atraso_6m)
                 THEN 1 ELSE 0 END)                                          AS n_dias12m_gt_6m,
        SUM(CASE WHEN COALESCE(saldo_vig_m2, 0) <> 0
                   OR clasificacion_m2 IS NOT NULL
                   OR saldo_cast_m2    IS NOT NULL
                   OR saldo_jud_m2     IS NOT NULL
                   OR saldo_ref_m2     IS NOT NULL
                   OR saldo_rest_m2    IS NOT NULL
                   OR COALESCE(dm_org_m2, 0) <> 0
                 THEN 1 ELSE 0 END)                                          AS n_con_m2,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN saldo_vig_m0 IS NULL OR saldo_vig_m0 <= 0 THEN 1 ELSE 0 END) AS c_saldo_vig_m0,
        SUM(CASE WHEN ent_alta IS NULL OR TRIM(ent_alta) = '' THEN 1 ELSE 0 END)   AS c_sin_ent_alta,
        SUM(CASE WHEN ent_alta IS DISTINCT FROM cod_instit_financiera THEN 1 ELSE 0 END) AS c_ent_alta_incoh,
        SUM(CASE WHEN nro_miss06 IS NULL OR nro_miss06 NOT BETWEEN 0 AND 6
                   OR nro_miss09 IS NULL OR nro_miss09 NOT BETWEEN 0 AND 9
                   OR nro_miss12 IS NULL OR nro_miss12 NOT BETWEEN 0 AND 12
                 THEN 1 ELSE 0 END)                                          AS c_miss_rango,
        SUM(CASE WHEN COALESCE(nro_miss06, 0) > COALESCE(nro_miss09, 0)
                   OR COALESCE(nro_miss09, 0) > COALESCE(nro_miss12, 0)
                 THEN 1 ELSE 0 END)                                          AS c_miss_monot,
        SUM(CASE WHEN (dias_atraso_6m IS NOT NULL
                       AND (dias_atraso_9m IS NULL OR dias_atraso_9m < dias_atraso_6m))
                   OR (dias_atraso_9m IS NOT NULL
                       AND (dias_atraso_12m IS NULL OR dias_atraso_12m < dias_atraso_9m))
                   OR COALESCE(jud_12um, 0)  < COALESCE(jud_06um, 0)
                   OR COALESCE(cast_12um, 0) < COALESCE(cast_06um, 0)
                   OR COALESCE(ref_12um, 0)  < COALESCE(ref_06um, 0)
                   OR COALESCE(ree_12um, 0)  < COALESCE(ree_06um, 0)
                   OR COALESCE(ven_12um, 0)  < COALESCE(ven_06um, 0)
                 THEN 1 ELSE 0 END)                                          AS c_q1_monot,
        SUM(CASE WHEN COALESCE(jud_12um, 0)  NOT IN (0, 1)
                   OR COALESCE(cast_12um, 0) NOT IN (0, 1)
                   OR COALESCE(ref_12um, 0)  NOT IN (0, 1)
                   OR COALESCE(ree_12um, 0)  NOT IN (0, 1)
                   OR COALESCE(ven_12um, 0)  NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                          AS c_flag_dom,
        SUM(CASE WHEN COALESCE(dias_atraso_12m, 0) < 0
                   OR COALESCE(dm_fm0, 0) < 0
                   OR COALESCE(dm_org_m2, 0) < 0
                 THEN 1 ELSE 0 END)                                          AS c_dm_neg,
        SUM(CASE WHEN flg_reactiva IS NULL OR flg_reactiva NOT IN (0, 1)
                   OR flg_solo_reactiva IS NULL OR flg_solo_reactiva NOT IN (0, 1)
                   OR flag_cons IS NULL OR flag_cons NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                          AS c_flg_reactiva_dom,
        SUM(CASE WHEN COALESCE(flg_garantia, '') NOT IN ('01.1 Garantia Preferida',
                                                         '01. Garantia NoPreferida',
                                                         '02. Sin Garantia')
                 THEN 1 ELSE 0 END)                                          AS c_garantia_dom
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
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n_dias12m_gt_6m,
    a.n_con_m2,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.c_saldo_vig_m0 > 0                   THEN 1 ELSE 0 END AS falla_saldo_vig_m0,
    CASE WHEN a.c_sin_ent_alta > 0                   THEN 1 ELSE 0 END AS falla_sin_ent_alta,
    CASE WHEN a.c_ent_alta_incoh > 0                 THEN 1 ELSE 0 END AS falla_ent_alta_incoh,
    CASE WHEN a.c_miss_rango > 0                     THEN 1 ELSE 0 END AS falla_nro_miss_rango,
    CASE WHEN a.c_miss_monot > 0                     THEN 1 ELSE 0 END AS falla_nro_miss_monot,
    CASE WHEN a.c_q1_monot > 0                       THEN 1 ELSE 0 END AS falla_q1_ventana_monot,
    CASE WHEN a.n_dias12m_gt_6m = 0                  THEN 1 ELSE 0 END AS falla_q1_12m_igual_6m,
    CASE WHEN a.c_flag_dom > 0                       THEN 1 ELSE 0 END AS falla_flag_dominio,
    CASE WHEN a.c_dm_neg > 0                         THEN 1 ELSE 0 END AS falla_dm_neg,
    CASE WHEN a.c_flg_reactiva_dom > 0               THEN 1 ELSE 0 END AS falla_flg_reactiva_dom,
    CASE WHEN a.c_garantia_dom > 0                   THEN 1 ELSE 0 END AS falla_garantia_dom,
    CASE WHEN a.n_con_m2 = 0                         THEN 1 ELSE 0 END AS falla_a7_m2_vacio
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
