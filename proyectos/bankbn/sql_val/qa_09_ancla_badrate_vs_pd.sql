-- qa_09_ancla_badrate_vs_pd.sql | insumo del ancla por corte y anio: badrate de target_12m contra avg pd_raw, y limpio contra sucio | leer columna diag y el signo de gap_pd_menos_badrate
WITH b AS (
    SELECT '1_CALIB_TODO' AS corte, CAST(codmes AS VARCHAR) AS cm, substr(CAST(codmes AS VARCHAR), 1, 4) AS anio, target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_calib = 1
    UNION ALL
    SELECT '2_CALIB_CLEAN1', CAST(codmes AS VARCHAR), substr(CAST(codmes AS VARCHAR), 1, 4), target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_calib = 1 AND flg_clean = 1
    UNION ALL
    SELECT '3_CALIB_DIRTY0', CAST(codmes AS VARCHAR), substr(CAST(codmes AS VARCHAR), 1, 4), target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_calib = 1 AND flg_clean = 0
    UNION ALL
    SELECT '4_ANCLA_IBK_CLEAN', CAST(codmes AS VARCHAR), substr(CAST(codmes AS VARCHAR), 1, 4), target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_calib = 1 AND flg_clean = 1 AND cod_instit_financiera = '00002'
),
g AS (
    SELECT
        corte,
        CASE WHEN grouping(anio) = 1 THEN 'TOTAL' ELSE anio END AS anio,
        CAST(count(1) AS BIGINT) AS n,
        CAST(count(DISTINCT cm) AS BIGINT) AS n_meses,
        min(cm) AS mes_min,
        max(cm) AS mes_max,
        CAST(count(target_12m) AS BIGINT) AS n_den,
        CAST(sum(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_malo,
        CAST(sum(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS n_pd_null,
        avg(pd_raw) AS avg_pd,
        min(pd_raw) AS min_pd,
        max(pd_raw) AS max_pd
    FROM b
    GROUP BY corte, GROUPING SETS ((anio), ())
)
SELECT
    corte,
    anio,
    n,
    n_meses,
    mes_min,
    mes_max,
    n_den,
    n_malo,
    n_pd_null,
    round(100e0 * n_malo / nullif(n_den, 0), 4) AS badrate_12m_pct,
    round(100e0 * avg_pd, 4) AS avg_pd_pct,
    round(100e0 * (avg_pd - CAST(n_malo AS DOUBLE) / nullif(CAST(n_den AS DOUBLE), 0)), 4) AS gap_pp,
    round(min_pd, 6) AS min_pd,
    round(max_pd, 6) AS max_pd,
    CASE
        WHEN n = 0 THEN 'SIN_FILAS'
        WHEN n_pd_null > 0 THEN 'FALLA_PD_NULA_EN_CALIB'
        WHEN n_den <> n THEN 'FALLA_TARGET_NULO_EN_CALIB'
        WHEN n_malo = 0 THEN 'FALLA_BADRATE_CERO'
        WHEN n_malo = n_den THEN 'FALLA_BADRATE_UNO'
        WHEN avg_pd IS NULL OR avg_pd <= 0 OR avg_pd >= 1 THEN 'FALLA_PD_FUERA_RANGO'
        WHEN avg_pd < CAST(n_malo AS DOUBLE) / nullif(CAST(n_den AS DOUBLE), 0) THEN 'REVISAR_DIRECCION_INVERTIDA'
        ELSE 'OK'
    END AS diag
FROM g
ORDER BY corte, anio
