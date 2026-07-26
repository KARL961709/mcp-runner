-- v_40_cal.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_cal (etapa 40)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--     El desglose por codmes ya lo da qa_1_reconcilia.sql, aqui van solo los invariantes.
--  3. Grano declarado en 4b_cal.sql: (codmes, tip_doc, key_value).
--  4. 4b no se tramifica: lee drivers ya completa acotando a 202206-202506. n_filas debe coincidir
--     con las filas de drivers en esa misma ventana (falla_vs_drivers).
--  5. s3 / s2 / s1 son las tres bolsas de caso_filtros.signed.yaml:
--       s3 = CASO3 (12 filtros que mandan a flg_clean = 99)
--       s2 = CASO2 (12 filtros a m0-2 que separan clean de dirty)
--       s1 = CASO1 (6 filtros que solo marcan y no excluyen)
--     falla_flg_clean_recalc recalcula la cascada 99 / 98 / 1 / 0 y la compara con la almacenada.
--  6. A7: s2 se alimenta de las columnas *_m2 y *_12um_v2 de mad. Si n_s2 = 0 en toda la tabla,
--     el rezago m0-2 no viajo y todo lo elegible saldria clean por construccion.
--  7. Q1: target_12m debe contener a target_06m. falla_q1_12m_igual_6m marca el bug viejo.
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
        CAST(t.entidad               AS VARCHAR) AS entidad,
        CAST(t.segmento_reactiva     AS VARCHAR) AS segmento_reactiva,
        t.pd_raw,
        t.flg_clean,
        t.target_06m,
        t.target_09m,
        t.target_12m,
        t.filtro_top4,
        t.falla_entidad,
        t.falla_madurez,
        t.falla_dup,
        t.filtro_perfil_empresa + t.filtro_deuda_comercial + t.filtro_ent_honrada
            + t.filtro_excl_entidades + t.filtro_alta + t.filtro_monto_endeud
            + t.filtro_saldo_vig_m0 + t.filtro_pnsn + t.filtro_top4
            + t.filtro_reactiva_puro + t.filtro_impulsa_u12m + t.filtro_impulsa_m0 AS s3,
        t.filtro_castigado_org + t.filtro_judicial_org + t.filtro_reest_org
            + t.filtro_refin_org + t.filtro_clasif_no_normal + t.filtro_diasatraso_org
            + t.filtro_sbs_no_normal_1um + t.filtro_novig_1um + t.filtro_edad_titular
            + t.filtro_edad_rrll + t.filtro_novig_12um + t.filtro_rrll_cast_12um AS s2,
        t.filtro_sunat_estado + t.filtro_sunat_giro + t.filtro_sunat_ubigeo
            + t.filtro_especiales + t.filtro_indeterminado + t.filtro_madurez_blanda AS s1,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin,
        p.n_meses_esp
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal t
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
        SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS n99,
        SUM(CASE WHEN flg_clean = 98 THEN 1 ELSE 0 END) AS n98,
        SUM(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END) AS n_clean,
        SUM(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END) AS n_dirty,
        SUM(CASE WHEN s3 > 0 THEN 1 ELSE 0 END)         AS n_s3,
        SUM(CASE WHEN s2 > 0 THEN 1 ELSE 0 END)         AS n_s2,
        SUM(CASE WHEN s1 > 0 THEN 1 ELSE 0 END)         AS n_s1,
        SUM(CASE WHEN flg_clean = 1 AND target_12m = 1 THEN 1 ELSE 0 END) AS n_clean_malo,
        SUM(CASE WHEN target_12m <> target_06m THEN 1 ELSE 0 END)         AS n_target12_dif_06m,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                          AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                          AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN flg_clean IS NULL OR flg_clean NOT IN (0, 1, 98, 99)
                 THEN 1 ELSE 0 END)                                          AS c_clean_dom,
        SUM(CASE WHEN flg_clean IS DISTINCT FROM (
                        CASE WHEN s3 > 0            THEN 99
                             WHEN pd_raw IS NULL    THEN 98
                             WHEN s2 = 0            THEN 1
                             ELSE 0 END)
                 THEN 1 ELSE 0 END)                                          AS c_clean_recalc,
        SUM(CASE WHEN s3 IS NULL OR s3 NOT BETWEEN 0 AND 12
                   OR s2 IS NULL OR s2 NOT BETWEEN 0 AND 12
                   OR s1 IS NULL OR s1 NOT BETWEEN 0 AND 6
                 THEN 1 ELSE 0 END)                                          AS c_filtro_dom,
        SUM(CASE WHEN flg_clean IN (0, 1)
                  AND (pd_raw IS NULL OR pd_raw <= 0 OR pd_raw >= 1)
                 THEN 1 ELSE 0 END)                                          AS c_pd_rango,
        SUM(CASE WHEN flg_clean = 98 AND pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS c_pd98_con_score,
        SUM(CASE WHEN flg_clean IN (0, 1)
                  AND (target_06m IS NULL OR target_09m IS NULL OR target_12m IS NULL)
                 THEN 1 ELSE 0 END)                                          AS c_target_nulo,
        SUM(CASE WHEN COALESCE(target_06m, 0) > COALESCE(target_09m, 0)
                   OR COALESCE(target_09m, 0) > COALESCE(target_12m, 0)
                 THEN 1 ELSE 0 END)                                          AS c_target_monot,
        SUM(CASE WHEN COALESCE(falla_madurez, 0) = 1 THEN 1 ELSE 0 END)      AS c_madurez,
        SUM(CASE WHEN COALESCE(falla_entidad, 0) = 1 THEN 1 ELSE 0 END)      AS c_falla_entidad,
        SUM(CASE WHEN COALESCE(falla_dup, 0) = 1 THEN 1 ELSE 0 END)          AS c_falla_dup,
        SUM(CASE WHEN (COALESCE(filtro_top4, 1) = 0
                       AND COALESCE(entidad, '') NOT IN ('BCP', 'BBVA', 'SCOTIA', 'IBK'))
                   OR (COALESCE(filtro_top4, 0) = 1
                       AND COALESCE(entidad, '') IN ('BCP', 'BBVA', 'SCOTIA', 'IBK'))
                 THEN 1 ELSE 0 END)                                          AS c_top4_incoh,
        SUM(CASE WHEN flg_clean IN (0, 1)
                  AND COALESCE(entidad, '') NOT IN ('BCP', 'BBVA', 'SCOTIA', 'IBK')
                 THEN 1 ELSE 0 END)                                          AS c_clean_fuera_top4,
        SUM(CASE WHEN COALESCE(segmento_reactiva, '') NOT IN ('SOLO NEGOCIO', 'MIXTO',
                                                              'REACTIVA', 'SIN DEUDA')
                 THEN 1 ELSE 0 END)                                          AS c_segmento_dom
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
),
src AS (
    SELECT COUNT(*) AS n_drivers
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers dr
    CROSS JOIN par p
    WHERE CAST(dr.codmes AS VARCHAR) BETWEEN p.mes_ini AND p.mes_fin
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_entidades,
    a.n99,
    a.n98,
    a.n_clean,
    a.n_dirty,
    a.n_s3,
    a.n_s2,
    a.n_s1,
    a.n_clean_malo,
    a.n_target12_dif_06m,
    m.n_filas_mes_min,
    m.n_filas_mes_max,
    s.n_drivers,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.n_meses <> q.n_meses_esp             THEN 1 ELSE 0 END AS falla_meses_incompleto,
    CASE WHEN a.n_filas <> s.n_drivers               THEN 1 ELSE 0 END AS falla_vs_drivers,
    CASE WHEN a.n_filas <> a.n99 + a.n98 + a.n_clean + a.n_dirty
                                                     THEN 1 ELSE 0 END AS falla_descuadre_clean,
    CASE WHEN a.c_clean_dom > 0                      THEN 1 ELSE 0 END AS falla_dominio_clean,
    CASE WHEN a.c_clean_recalc > 0                   THEN 1 ELSE 0 END AS falla_flg_clean_recalc,
    CASE WHEN a.c_filtro_dom > 0                     THEN 1 ELSE 0 END AS falla_filtro_dominio,
    CASE WHEN a.c_pd_rango > 0                       THEN 1 ELSE 0 END AS falla_pd_rango,
    CASE WHEN a.c_pd98_con_score > 0                 THEN 1 ELSE 0 END AS falla_pd98_con_score,
    CASE WHEN a.c_target_nulo > 0                    THEN 1 ELSE 0 END AS falla_target_nulo,
    CASE WHEN a.c_target_monot > 0                   THEN 1 ELSE 0 END AS falla_q1_target_monot,
    CASE WHEN a.n_target12_dif_06m = 0               THEN 1 ELSE 0 END AS falla_q1_12m_igual_6m,
    CASE WHEN a.n_s2 = 0                             THEN 1 ELSE 0 END AS falla_a7_caso2_vacio,
    CASE WHEN a.c_madurez > 0                        THEN 1 ELSE 0 END AS falla_madurez,
    CASE WHEN a.c_falla_entidad > 0                  THEN 1 ELSE 0 END AS falla_entidad,
    CASE WHEN a.c_falla_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_marcado,
    CASE WHEN a.c_top4_incoh > 0                     THEN 1 ELSE 0 END AS falla_top4_incoh,
    CASE WHEN a.c_clean_fuera_top4 > 0               THEN 1 ELSE 0 END AS falla_clean_fuera_top4,
    CASE WHEN a.c_segmento_dom > 0                   THEN 1 ELSE 0 END AS falla_segmento_dom
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN mes m
CROSS JOIN src s
CROSS JOIN par q
