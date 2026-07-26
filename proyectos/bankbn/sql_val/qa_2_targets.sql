-- QA2. TARGETS 06m/09m/12m sobre flg_clean=1: rango, madurez calendario, monotonia, deteccion Q1 y cross-check mora (read-only)
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, 202606 AS snap_rcc
),
base AS (
    SELECT
        c.codmes,
        c.target_06m,
        c.target_09m,
        c.target_12m,
        m.dias_atraso_6m,
        m.dias_atraso_9m,
        m.dias_atraso_12m,
        CASE WHEN m.codmes IS NULL THEN 1 ELSE 0 END AS sin_mad,
        p.snap_rcc
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
    CROSS JOIN par p
    LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_mad m
        ON  m.codmes    = c.codmes
        AND m.tip_doc   = c.tip_doc
        AND m.key_value = c.key_value
    WHERE c.flg_clean = 1
      AND c.codmes BETWEEN p.mes_ini AND p.mes_fin
),
largo AS (
    SELECT
        b.codmes,
        b.sin_mad,
        b.snap_rcc,
        b.target_06m,
        b.target_09m,
        b.target_12m,
        h.horizonte,
        h.meses_h,
        h.tgt,
        h.atr
    FROM base b
    CROSS JOIN UNNEST(ARRAY[
        ROW('06m',  6, b.target_06m, b.dias_atraso_6m),
        ROW('09m',  9, b.target_09m, b.dias_atraso_9m),
        ROW('12m', 12, b.target_12m, b.dias_atraso_12m)
    ]) AS h (horizonte, meses_h, tgt, atr)
)
SELECT
    horizonte,
    COALESCE(codmes, 'ZZ_TOTAL') AS mes,
    COUNT(*)                                                              AS n,
    SUM(CASE WHEN tgt = 1 THEN 1 ELSE 0 END)                              AS n_malos,
    CAST(SUM(CASE WHEN tgt = 1 THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(COUNT(*), 0)                                             AS td,
    SUM(CASE WHEN tgt IS NULL OR tgt NOT IN (0, 1) THEN 1 ELSE 0 END)     AS falla_rango,
    SUM(CASE WHEN (COALESCE(TRY_CAST(codmes AS INTEGER), 0) / 100) * 12
                + MOD(COALESCE(TRY_CAST(codmes AS INTEGER), 0), 100)
                + meses_h
                > (snap_rcc / 100) * 12 + MOD(snap_rcc, 100)
             THEN 1 ELSE 0 END)                                           AS falla_madurez,
    SUM(CASE WHEN target_06m > target_09m THEN 1 ELSE 0 END)              AS falla_monot_0609,
    SUM(CASE WHEN target_09m > target_12m THEN 1 ELSE 0 END)              AS falla_monot_0912,
    SUM(CASE WHEN target_12m <> target_06m THEN 1 ELSE 0 END)             AS n_dif_t12_t06,
    CASE WHEN SUM(CASE WHEN target_12m <> target_06m THEN 1 ELSE 0 END) = 0
         THEN 1 ELSE 0 END                                                AS falla_q1_t12_copia_t06,
    SUM(CASE WHEN atr > 90 AND COALESCE(tgt, 0) <> 1 THEN 1 ELSE 0 END)   AS falla_xcheck_mora,
    SUM(CASE WHEN tgt = 1 AND (atr IS NULL OR atr <= 90) THEN 1 ELSE 0 END) AS n_malo_por_evento,
    SUM(sin_mad)                                                          AS falla_sin_mad
FROM largo
GROUP BY GROUPING SETS ((horizonte, codmes), (horizonte))
ORDER BY 1, 2
