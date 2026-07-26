-- QA1. RECONCILIACION ds_adm_bpe_bankbn_cal por codmes: n/n99/n98/clean/dirty, descuadre, rangos y filtros NULL (read-only)
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, 202606 AS snap_rcc
),
base AS (
    SELECT
        c.codmes,
        CAST(c.tip_doc   AS VARCHAR) AS tip_doc,
        CAST(c.key_value AS VARCHAR) AS key_value,
        c.cod_instit_financiera,
        c.flg_ppjj,
        c.flg_impulsa,
        c.flg_impulsa_u12m,
        c.flag_bpe_parcial,
        c.pd_raw,
        c.target_06m,
        c.target_09m,
        c.target_12m,
        c.flg_clean,
        p.mes_ini,
        p.mes_fin,
        p.snap_rcc
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
    CROSS JOIN par p
)
SELECT
    COALESCE(codmes, 'ZZ_TOTAL') AS mes,
    COUNT(*)                                                              AS n,
    SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                       AS n99,
    SUM(CASE WHEN flg_clean = 98 THEN 1 ELSE 0 END)                       AS n98,
    SUM(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                       AS n_clean,
    SUM(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)                       AS n_dirty,
    COUNT(*) - SUM(CASE WHEN flg_clean IN (0, 1, 98, 99) THEN 1 ELSE 0 END) AS descuadre,
    COUNT(*) - COUNT(DISTINCT COALESCE(codmes, '?') || '|' || COALESCE(tip_doc, '?') || '|' || COALESCE(key_value, '?')) AS n_dup,
    COUNT(DISTINCT cod_instit_financiera)                                 AS n_entidades,
    CASE WHEN COUNT(*) - SUM(CASE WHEN flg_clean IN (0, 1, 98, 99) THEN 1 ELSE 0 END) <> 0
         THEN 1 ELSE 0 END                                                AS falla_descuadre,
    CASE WHEN COUNT(*) - COUNT(DISTINCT COALESCE(codmes, '?') || '|' || COALESCE(tip_doc, '?') || '|' || COALESCE(key_value, '?')) <> 0
         THEN 1 ELSE 0 END                                                AS falla_grano_dup,
    CASE WHEN COUNT(DISTINCT cod_instit_financiera) > 4 THEN 1 ELSE 0 END AS falla_ent_top4,
    SUM(CASE WHEN flg_clean IS NULL OR flg_clean NOT IN (0, 1, 98, 99)
             THEN 1 ELSE 0 END)                                           AS falla_dominio_clean,
    SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
             THEN 1 ELSE 0 END)                                           AS falla_codmes_fmt,
    SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS falla_rango_codmes,
    SUM(CASE WHEN flg_clean IN (0, 1)
              AND COALESCE(TRY_CAST(codmes AS INTEGER), 0) + 100 > snap_rcc
             THEN 1 ELSE 0 END)                                           AS falla_madurez_12m,
    SUM(CASE WHEN tip_doc IS NULL OR key_value IS NULL THEN 1 ELSE 0 END) AS falla_key_null,
    SUM(CASE WHEN cod_instit_financiera IS NULL
                OR flg_ppjj              IS NULL
                OR flg_impulsa           IS NULL
                OR flg_impulsa_u12m      IS NULL
                OR flag_bpe_parcial      IS NULL
             THEN 1 ELSE 0 END)                                           AS falla_filtro_null,
    SUM(CASE WHEN flg_clean IN (0, 1)
              AND (pd_raw IS NULL OR pd_raw <= 0 OR pd_raw >= 1)
             THEN 1 ELSE 0 END)                                           AS falla_pd_rango,
    SUM(CASE WHEN flg_clean = 98 AND pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS falla_pd98_con_score,
    SUM(CASE WHEN flg_clean = 1
              AND (target_06m IS NULL OR target_09m IS NULL OR target_12m IS NULL)
             THEN 1 ELSE 0 END)                                           AS falla_target_null
FROM base
GROUP BY GROUPING SETS ((codmes), ())
ORDER BY 1
