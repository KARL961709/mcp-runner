-- qa_07_serie_mensual.sql | una fila por codmes con po mad cal score badrate y pd: detecta huecos, burn-in, escalones de tramo, bordes de la ventana calibrable y saltos de cobertura de score
WITH p AS (
    SELECT CAST(codmes AS VARCHAR) AS cm,
           CAST(count(1) AS BIGINT) AS n_po,
           CAST(sum(CASE WHEN altas = 'A-12' THEN 1 ELSE 0 END) AS BIGINT) AS n_a12,
           CAST(sum(CASE WHEN CAST(cod_instit_financiera AS VARCHAR) = '00002' THEN 1 ELSE 0 END) AS BIGINT) AS n_ibk,
           CAST(sum(CASE WHEN COALESCE(saldo_m12, 0) = 0 THEN 1 ELSE 0 END) AS BIGINT) AS n_sm12_cero
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    GROUP BY 1
),
m AS (
    SELECT CAST(codmes AS VARCHAR) AS cm,
           CAST(count(1) AS BIGINT) AS n_mad,
           round(avg(CAST(nro_miss12 AS DOUBLE)), 3) AS prom_miss12
    FROM disc_model_owner.ds_adm_bpe_bankbn_mad
    GROUP BY 1
),
c AS (
    SELECT CAST(codmes AS VARCHAR) AS cm,
           CAST(count(1) AS BIGINT) AS n_cal,
           CAST(count(pd_raw) AS BIGINT) AS n_score,
           CAST(sum(CASE WHEN falla_madurez = 0 THEN 1 ELSE 0 END) AS BIGINT) AS n_maduro,
           CAST(sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS BIGINT) AS n_c99,
           CAST(sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_c1,
           CAST(sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END) AS BIGINT) AS n_c0,
           CAST(sum(flg_calib) AS BIGINT) AS n_calib,
           CAST(sum(CASE WHEN flg_calib = 1 AND target_12m = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_malo_calib,
           avg(CASE WHEN flg_calib = 1 THEN pd_raw END) AS avg_pd_calib
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
    GROUP BY 1
),
mes AS (
    SELECT cm FROM p
    UNION
    SELECT cm FROM m
    UNION
    SELECT cm FROM c
)
SELECT
    x.cm AS codmes,
    COALESCE(p.n_po, 0) AS n_po,
    COALESCE(m.n_mad, 0) AS n_mad,
    COALESCE(c.n_cal, 0) AS n_cal,
    COALESCE(c.n_cal, 0) - COALESCE(m.n_mad, 0) AS dif_cal_mad,
    round(100e0 * p.n_a12 / nullif(p.n_po, 0), 2) AS pct_a12,
    round(100e0 * p.n_sm12_cero / nullif(p.n_po, 0), 2) AS pct_sm12_cero,
    round(100e0 * p.n_ibk / nullif(p.n_po, 0), 2) AS pct_ibk,
    m.prom_miss12,
    COALESCE(c.n_score, 0) AS n_score,
    round(100e0 * c.n_score / nullif(c.n_cal, 0), 2) AS pct_score,
    COALESCE(c.n_maduro, 0) AS n_maduro12,
    COALESCE(c.n_c99, 0) AS n_clean99,
    COALESCE(c.n_c1, 0) AS n_clean1,
    COALESCE(c.n_c0, 0) AS n_clean0,
    COALESCE(c.n_calib, 0) AS n_calib,
    COALESCE(c.n_malo_calib, 0) AS n_malo_calib,
    round(100e0 * c.n_malo_calib / nullif(c.n_calib, 0), 4) AS badrate_calib_pct,
    round(100e0 * c.avg_pd_calib, 4) AS avg_pd_calib_pct
FROM mes x
LEFT JOIN p ON p.cm = x.cm
LEFT JOIN m ON m.cm = x.cm
LEFT JOIN c ON c.cm = x.cm
ORDER BY 1
