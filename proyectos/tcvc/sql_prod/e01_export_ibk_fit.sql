-- e01. Export parquet del fit IBK (row-level, clean+dirty, todas las cohortes, SIN key_value) + bucket
--      dsc_flg_malo_12m (join 1:1 a _2_v2 post-dedup) para segmentar UNCASHED/INSUFICIENTE en el fit. -Bajar.
CREATE TABLE disc_model_owner.tcvc_fit_ibk_export
WITH (format = 'PARQUET', write_compression = 'SNAPPY', external_location = '<S3_DATOS>/tcvc_fit/') AS
SELECT d.codmes, d.cod_instit_financiera, d.flg_ibk, d.tipo_ingreso, d.nodo,
       d.pd_raw, d.flg_pd_raw, d.flg_clean, d.flg_calib, d.target_01m, d.target_02m, d.target_03m, d.target_04m, d.target_05m, d.target_06m, d.target_07m, d.target_08m, d.target_09m, d.target_10m, d.target_11m, d.target_12m,
       t.dsc_flg_malo_12m
FROM disc_model_owner.ds_adm_tcbank_cal d
LEFT JOIN disc_model_owner.enr_admtcbk_2_v2 t
  ON d.codmes = t.codmes AND d.tip_doc = t.tip_doc AND d.key_value = t.key_value
 AND d.cod_instit_financiera = t.cod_instit_financiera
WHERE d.flg_ibk = 1