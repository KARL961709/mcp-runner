-- desemb_escopt.sql | tabla NUEVA disc_model_owner.b46029_desemb_escopt_202609
--   = desembolsos (b46029_desemb_cal_202609) + PD del ESCENARIO OPTIMO scoreada por el banco.
--   pd_esc_opt = prob_modelo_cal (bankbn V2, scr_admbankbpe_calibrado) x factor anti-conservador por personeria
--                (tip_doc='2' PJJ -> 0.68140 ; else PNN -> 0.96970), acotada a (1e-6, 1-1e-6).
--   Cruce: (tip_doc, key_value, p_codmes = cod_mes del desembolso). scr deduplicado por fec_replica (rn=1).
--   flg_match=0 si el cliente no tiene score bankbn ese p_codmes (scr cubre p_codmes 202206-202607).
--   Para bajar la tabla a local: .\Go.ps1 -Only desemb_escopt -Bajar
CREATE TABLE disc_model_owner.b46029_desemb_escopt_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH s AS (
  SELECT CAST(p_codmes AS INTEGER) AS p_codmes,
         tip_doc,
         key_value,
         TRY_CAST(probabilidad AS DOUBLE) AS prob_raw_scr,
         prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
)
SELECT d.cod_mes,
       d.cod_tip_doc,
       d.key_value,
       d.desc_producto,
       d.desc_cliente,
       d.pd_raw,
       d.mto_desembolso,
       d.meses_madurez,
       d.target_12m,
       s.prob_raw_scr,
       s.prob_modelo_cal                                   AS pd_cal_bankbn,
       GREATEST(1e-6, LEAST(1 - 1e-6,
         s.prob_modelo_cal * CASE WHEN d.cod_tip_doc = '2' THEN 0.68140 ELSE 0.96970 END)) AS pd_esc_opt,
       CASE WHEN s.prob_modelo_cal IS NULL THEN 0 ELSE 1 END AS flg_match
FROM disc_model_owner.b46029_desemb_cal_202609 d
LEFT JOIN s
  ON  s.tip_doc   = d.cod_tip_doc
 AND  s.key_value = d.key_value
 AND  s.p_codmes  = d.cod_mes
 AND  s.rn        = 1
