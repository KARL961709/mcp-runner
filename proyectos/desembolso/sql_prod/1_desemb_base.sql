-- 1_desemb_base.sql | tabla NUEVA disc_model_owner.b46029_desemb_base_202609: universo de desembolsos (d_perm_aws.user_desembolso, TODAS las filas) con el pd_raw CRUDO del scorecard Origen BPE = probabilidad de e_perm_aws.scr_admbankbpe_rsk (fuente cruda confirmada en f3_cal/4b_cal.sql y f6/4b_scoring_v1v2.sql). CRUCE por CAMPANA p_codmes = cod_mes (replica los Recibidos: join por tip_doc+key_value+p_codmes, un mes entero, sin as-of). En scr_admbankbpe_rsk p_codmes es la fecha de CAMPANA y codmes es el periodo RCC (= p_codmes-1); por eso el score de un desembolso del mes M tiene p_codmes=M y codmes=M-1 (sin look-ahead). Grano por p_codmes 1a1 (diag 28). Un solo modelo ADMBANKBPE (diag 29), y el max(probabilidad) solo colapsa 4 filas duplicadas de probabilidad identica (diag 28), no elige score. Grano cod_mes x cod_tip_doc x key_value x desc_producto (arrastra las 8 columnas de user_desembolso, desc_cliente y desc_campania por max, lossless por ser 1a1). sin_pd=1 si el cliente no tiene score de campana p_codmes=cod_mes. flg_impulsa=1 en IMPULSO 202402-202412. lag_meses = cod_mes - score_codmes (= 1: el score usa RCC del mes previo). Base para la nueva calibracion, el target se agrega en el paso 2
CREATE TABLE disc_model_owner.b46029_desemb_base_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH ud AS (
  SELECT cast(cod_mes AS int) AS cod_mes, cod_tip_doc, key_value, desc_producto,
         count(*) AS n_desemb,
         sum(cast(mto_desembolso AS double)) AS mto_desembolso,
         max(flg_desembolso) AS flg_desembolso,
         max(desc_cliente) AS desc_cliente,
         max(desc_campania) AS desc_campania
  FROM d_perm_aws.user_desembolso
  GROUP BY cast(cod_mes AS int), cod_tip_doc, key_value, desc_producto
),
udk AS (
  SELECT DISTINCT cod_mes, cod_tip_doc, key_value FROM ud
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(p_codmes AS int) AS score_pcod,
         max(cast(codmes AS int)) AS score_codmes,
         max(cast(probabilidad AS double)) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND modelo = 'ADMBANKBPE' AND p_codmes BETWEEN '202301' AND '202608'
  GROUP BY cast(tip_doc AS varchar), key_value, cast(p_codmes AS int)
),
asof AS (
  SELECT udk.cod_mes, udk.cod_tip_doc, udk.key_value, s.pd_raw, s.score_codmes
  FROM udk
  LEFT JOIN scr s ON s.tip_doc = udk.cod_tip_doc AND s.key_value = udk.key_value AND s.score_pcod = udk.cod_mes
)
SELECT ud.cod_mes, ud.cod_tip_doc, ud.key_value, ud.desc_producto,
       ud.desc_cliente, ud.desc_campania,
       ud.n_desemb, round(ud.mto_desembolso, 2) AS mto_desembolso, ud.flg_desembolso,
       a.pd_raw, a.score_codmes AS pd_codmes,
       cast(ud.cod_mes - a.score_codmes AS integer) AS lag_meses,
       CASE WHEN a.pd_raw IS NULL THEN 1 ELSE 0 END AS sin_pd,
       CASE WHEN ud.desc_producto = 'IMPULSO' AND ud.cod_mes BETWEEN 202402 AND 202412 THEN 1 ELSE 0 END AS flg_impulsa
FROM ud
LEFT JOIN asof a
  ON a.cod_mes = ud.cod_mes AND a.cod_tip_doc = ud.cod_tip_doc AND a.key_value = ud.key_value
