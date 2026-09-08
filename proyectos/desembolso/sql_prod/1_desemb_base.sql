-- 1_desemb_base.sql | tabla NUEVA disc_model_owner.b46029_desemb_base_202609: universo de desembolsos (d_perm_aws.user_desembolso, TODAS las filas) con el pd_raw CRUDO del modelo Origen BPE traido AS-OF (la alta BPE del cliente con codmes menor o igual al mes del desembolso, la mas cercana, sin look-ahead) mas flags. Grano cod_mes x cod_tip_doc x key_value x desc_producto. sin_pd=1 cuando el cliente no tiene score BPE previo (ej DIGITAL). flg_impulsa=1 en IMPULSO 202402-202412. Base para la nueva calibracion, el target se agrega en el paso 2
CREATE TABLE disc_model_owner.b46029_desemb_base_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH ud AS (
  SELECT cast(cod_mes AS int) AS cod_mes, cod_tip_doc, key_value, desc_producto,
         count(*) AS n_desemb,
         sum(cast(mto_desembolso AS double)) AS mto_desembolso,
         max(flg_desembolso) AS flg_desembolso
  FROM d_perm_aws.user_desembolso
  GROUP BY cast(cod_mes AS int), cod_tip_doc, key_value, desc_producto
),
udk AS (
  SELECT DISTINCT cod_mes, cod_tip_doc, key_value FROM ud
),
bpe AS (
  SELECT tip_doc, key_value, cast(codmes AS int) AS bcm, cast(pd_raw AS double) AS pd_raw
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
  WHERE pd_raw IS NOT NULL
),
asof AS (
  SELECT udk.cod_mes, udk.cod_tip_doc, udk.key_value, b.pd_raw, b.bcm,
         ROW_NUMBER() OVER (PARTITION BY udk.cod_mes, udk.cod_tip_doc, udk.key_value ORDER BY b.bcm DESC) AS rn
  FROM udk
  LEFT JOIN bpe b ON b.tip_doc = udk.cod_tip_doc AND b.key_value = udk.key_value AND b.bcm <= udk.cod_mes
)
SELECT ud.cod_mes, ud.cod_tip_doc, ud.key_value, ud.desc_producto,
       ud.n_desemb, round(ud.mto_desembolso, 2) AS mto_desembolso, ud.flg_desembolso,
       a.pd_raw, a.bcm AS pd_codmes,
       CASE WHEN a.pd_raw IS NULL THEN 1 ELSE 0 END AS sin_pd,
       CASE WHEN ud.desc_producto = 'IMPULSO' AND ud.cod_mes BETWEEN 202402 AND 202412 THEN 1 ELSE 0 END AS flg_impulsa
FROM ud
LEFT JOIN asof a
  ON a.cod_mes = ud.cod_mes AND a.cod_tip_doc = ud.cod_tip_doc AND a.key_value = ud.key_value AND a.rn = 1
