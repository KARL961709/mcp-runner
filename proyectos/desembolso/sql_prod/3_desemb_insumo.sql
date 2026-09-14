-- 3_desemb_insumo.sql | tabla FINAL disc_model_owner.b46029_desemb_cal_202609: une la base (poblacion user_desembolso + pd_raw crudo as-of offset+1, NULL si el cliente no tiene score previo) con el target_01m..12m (RCC entidad IBK). Insumo completo para la nueva calibracion sobre el universo de desembolsos. Grano cod_mes x cod_tip_doc x key_value x desc_producto
CREATE TABLE disc_model_owner.b46029_desemb_cal_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
SELECT b.cod_mes, b.cod_tip_doc, b.key_value, b.desc_producto,
       b.desc_cliente, b.desc_campania,
       b.n_desemb, b.mto_desembolso, b.flg_desembolso,
       b.pd_raw, b.pd_codmes, b.lag_meses, b.sin_pd, b.flg_impulsa,
       t.target_01m, t.target_02m, t.target_03m, t.target_04m, t.target_05m, t.target_06m,
       t.target_07m, t.target_08m, t.target_09m, t.target_10m, t.target_11m, t.target_12m,
       t.meses_madurez, t.rcc_frontera
FROM disc_model_owner.b46029_desemb_base_202609 b
LEFT JOIN disc_model_owner.b46029_desemb_target_202609 t
  ON t.cod_mes = b.cod_mes AND t.cod_tip_doc = b.cod_tip_doc AND t.key_value = b.key_value
