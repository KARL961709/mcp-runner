-- ============================================================================
-- 81. SERIE MENSUAL PARA SELECCION DE VARIABLE MACRO
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_81_macro
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY'
) AS
WITH m AS (
    SELECT CAST(cod_mes AS VARCHAR)                    AS codmes,
           TRY_CAST(rat_ipc              AS DOUBLE)    AS rat_ipc,
           TRY_CAST(rat_pbi              AS DOUBLE)    AS rat_pbi,
           TRY_CAST(rat_tasa_desempleo   AS DOUBLE)    AS rat_tasa_desempleo,
           TRY_CAST(rat_tasa_referencia  AS DOUBLE)    AS rat_tasa_referencia,
           TRY_CAST(rat_expect_inflacion AS DOUBLE)    AS rat_expect_inflacion,
           TRY_CAST(rat_term_intercambio AS DOUBLE)    AS rat_term_intercambio
    FROM (
        SELECT cod_mes, rat_ipc, rat_pbi, rat_tasa_desempleo, rat_tasa_referencia,
               rat_expect_inflacion, rat_term_intercambio,
               row_number() OVER (PARTITION BY cod_mes
                                  ORDER BY fec_proceso DESC) AS rn
        FROM e_perm_aws.t_fact_bpe_vars_macro) x
    WHERE x.rn = 1
),
s AS (
    SELECT codmes_mrm                                                                  AS codmes,
           count(*)                                                                    AS n_universo,
           sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)            AS n_clean,
           sum(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN 1 ELSE 0 END)      AS n_clean_macro,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_12m AS DOUBLE) END) AS rd_12m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_06m AS DOUBLE) END) AS rd_06m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_03m AS DOUBLE) END) AS rd_03m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN CAST(target_12m AS DOUBLE) END) AS rd_12m_macro,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN pd_raw END)              AS pd_raw_clean
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    GROUP BY codmes_mrm
)
SELECT s.codmes, s.n_universo, s.n_clean, s.n_clean_macro,
       s.rd_12m_clean, s.rd_06m_clean, s.rd_03m_clean, s.rd_12m_macro, s.pd_raw_clean,
       m.rat_ipc, m.rat_pbi, m.rat_tasa_desempleo, m.rat_tasa_referencia,
       m.rat_expect_inflacion, m.rat_term_intercambio
FROM s
LEFT JOIN m ON m.codmes = s.codmes
