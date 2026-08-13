-- ============================================================================
-- 94. EXPORT DE LA SERIE MACRO
--   scan: disc_model_owner.ds_adm_vcnbank_tc_81_macro, 88 filas
--   ancla: 93 exporta REGISTROS de cal con flg_clean_macro. Esta es la SERIE agregada
--          por codmes con las 7 variables del BCRP, que es lo que consume la seleccion
--          de variable macro. Sin ella el analisis no se puede correr en local
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_px_macro_serie
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = 's3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/tcnb/macro_serie/') AS
SELECT codmes, n_universo, n_clean, n_clean_macro,
       rd_12m_clean, rd_06m_clean, rd_03m_clean, rd_12m_macro, pd_raw_clean,
       rat_ipc, rat_pbi, rat_tasa_desempleo, rat_tasa_referencia,
       rat_expect_inflacion, rat_term_intercambio
FROM disc_model_owner.ds_adm_vcnbank_tc_81_macro
