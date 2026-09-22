-- desemb_corr_b_build.sql | BASE CORREGIDA: re-cruza el score a p_codmes = cod_mes - 1 (la admision se scorea con la campana del mes anterior). Trae pd_raw + puntuacion CRUDAS (scr_admbankbpe_rsk) + prob_modelo (=prob_modelo_cal del calibrado, referencia prod), todo del cruce corregido. Identidad + target/madurez del base actual (el target mide mora desde el desembolso, NO cambia). Dedup por fec_replica. p_codmes_cruce = cod_mes-1 con salto de ano. Para re-fitear la calibracion.
CREATE TABLE disc_model_owner.b46029_desemb_cal_corr_202609
WITH (format='PARQUET', parquet_compression='SNAPPY') AS
WITH b AS (
  SELECT cod_mes, cod_tip_doc, key_value, desc_producto, desc_cliente, desc_campania,
         n_desemb, mto_desembolso, flg_desembolso, flg_impulsa,
         target_01m, target_02m, target_03m, target_04m, target_05m, target_06m,
         target_07m, target_08m, target_09m, target_10m, target_11m, target_12m,
         meses_madurez, rcc_frontera,
         CASE WHEN cod_mes % 100 = 1 THEN cod_mes - 89 ELSE cod_mes - 1 END AS p_codmes_cruce
  FROM disc_model_owner.b46029_desemb_cal_202609
),
scr AS (
  SELECT CAST(p_codmes AS INT) AS pcm, tip_doc, key_value,
         TRY_CAST(probabilidad AS DOUBLE) AS pd_raw,
         puntuacion AS puntuacion,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE modelo = 'ADMBANKBPE' AND p_codmes BETWEEN '202212' AND '202607'
),
cal AS (
  SELECT CAST(p_codmes AS INT) AS pcm, tip_doc, key_value,
         prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
  WHERE p_codmes BETWEEN '202212' AND '202607'
)
SELECT b.cod_mes, b.cod_tip_doc, b.key_value, b.desc_producto, b.desc_cliente, b.desc_campania,
       b.n_desemb, b.mto_desembolso, b.flg_desembolso, b.flg_impulsa,
       b.target_01m,
         b.target_02m,
         b.target_03m,
         b.target_04m,
         b.target_05m,
         b.target_06m,
         b.target_07m,
         b.target_08m,
         b.target_09m,
         b.target_10m,
         b.target_11m,
         b.target_12m,
       b.meses_madurez, b.rcc_frontera,
       b.p_codmes_cruce,
       s.pd_raw AS pd_raw,
       s.puntuacion AS puntuacion,
       c.prob_modelo_cal AS prob_modelo,
       CASE WHEN s.pd_raw IS NULL THEN 1 ELSE 0 END AS sin_pd
FROM b
LEFT JOIN scr s ON s.tip_doc = b.cod_tip_doc AND s.key_value = b.key_value AND s.pcm = b.p_codmes_cruce AND s.rn = 1
LEFT JOIN cal c ON c.tip_doc = b.cod_tip_doc AND c.key_value = b.key_value AND c.pcm = b.p_codmes_cruce AND c.rn = 1
