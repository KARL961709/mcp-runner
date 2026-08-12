-- 93_export_macro.sql | serie mensual para la seleccion de variable macro contra el target largo. Grano codmes, no
-- cliente. Trae las SIETE variables de t_fact_bpe_vars_macro y no solo las dos que usaba la calibracion vigente,
-- porque la seleccion es una cascada y no una eleccion previa.
-- La tabla macro trae cerca de 8 filas por cod_mes (la q98 conto 96 meses por anio), asi que se dedupea con
-- ROW_NUMBER de orden total sobre fec_proceso. RANK no dedupea.
-- Se emiten las dos tasas: la del universo limpio y la de la variante macro, que suelta fraude y swaps para ganar
-- los meses en que esas fuentes no existen.
CREATE TABLE disc_model_owner.ds_adm_tcnb_px_macro
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location   = '<S3_DATOS>/adm_tcnb_px_macro/'
) AS
WITH m AS (
    SELECT CAST(cod_mes AS VARCHAR) AS codmes,
           TRY_CAST(rat_ipc              AS DOUBLE) AS rat_ipc,
           TRY_CAST(rat_pbi              AS DOUBLE) AS rat_pbi,
           TRY_CAST(rat_tasa_desempleo   AS DOUBLE) AS rat_tasa_desempleo,
           TRY_CAST(rat_tasa_referencia  AS DOUBLE) AS rat_tasa_referencia,
           TRY_CAST(rat_expect_inflacion AS DOUBLE) AS rat_expect_inflacion,
           TRY_CAST(rat_term_intercambio AS DOUBLE) AS rat_term_intercambio
    FROM (
        SELECT cod_mes, rat_ipc, rat_pbi, rat_tasa_desempleo, rat_tasa_referencia,
               rat_expect_inflacion, rat_term_intercambio,
               row_number() OVER (PARTITION BY cod_mes ORDER BY fec_proceso DESC) AS rn
        FROM e_perm_aws.t_fact_bpe_vars_macro) x
    WHERE x.rn = 1
),
s AS (
    SELECT codmes_mrm                                                                   AS codmes,
           count(*)                                                                     AS n_universo,
           sum(CASE WHEN flg_clean = 1 AND flg_calib = 1 THEN 1 ELSE 0 END)             AS n_clean,
           sum(CASE WHEN flg_clean_macro = 1 AND flg_calib = 1 THEN 1 ELSE 0 END)       AS n_clean_macro,
           avg(CASE WHEN flg_clean = 1 AND flg_calib = 1
                    THEN CAST(target_12m_corr AS DOUBLE) END)                           AS rd_clean,
           avg(CASE WHEN flg_clean_macro = 1 AND flg_calib = 1
                    THEN CAST(target_12m_corr AS DOUBLE) END)                           AS rd_macro,
           avg(CASE WHEN flg_clean = 1 AND flg_calib = 1 THEN pd_raw END)               AS pd_raw_clean
    FROM disc_model_owner.ds_adm_tcnb_cal
    GROUP BY codmes_mrm
)
SELECT s.codmes, s.n_universo, s.n_clean, s.n_clean_macro,
       s.rd_clean, s.rd_macro, s.pd_raw_clean,
       m.rat_ipc, m.rat_pbi, m.rat_tasa_desempleo, m.rat_tasa_referencia,
       m.rat_expect_inflacion, m.rat_term_intercambio
FROM s LEFT JOIN m ON m.codmes = s.codmes
